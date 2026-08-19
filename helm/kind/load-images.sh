#!/usr/bin/env bash
#
# Make all images the chart needs available inside the kind cluster WITHOUT the
# (slow / 403-throttled) in-cluster pulls. kind has no native image-preload in its
# cluster config, so this is the recorded "load step" — run it after creating the
# cluster and before `helm install`.
#
#   helm/kind/load-images.sh                    # cluster: gravitee-apim (single-node)
#   helm/kind/load-images.sh gravitee-apim-ha   # cluster: gravitee-apim-ha (prod mirror)
#
# ⚠️ Docker Desktop's "Use containerd for pulling and storing images" MUST be OFF.
# With the containerd image store ON, `kind load docker-image` fails with
# `ctr: content digest <sha> not found` (it exports a multi-platform manifest whose
# other-arch blobs aren't local). Turn it off in Settings → General, then re-pull.
#
set -euo pipefail
CLUSTER="${1:-gravitee-apim}"

# Gravitee component images: reuse whatever is already in local Docker (e.g. built
# by the docker-compose stack). The overlay pins these tags with pullPolicy IfNotPresent.
GRAVITEE_IMAGES=(
    graviteeio/apim-management-api:4.11.6
    graviteeio/apim-gateway:4.11.6
    graviteeio/apim-management-ui:4.11.6
    graviteeio/apim-portal-ui:latest
)

# Bitnami subchart images. Docker Hub 403-throttles the in-cluster containerd pulls,
# so pull them on the HOST first, then load. NOTE the chart's init image `os-shell`
# was moved to `bitnamilegacy` and is referenced with TWO different tags
# (sysctlImage r48, volumePermissions r51).
BITNAMI_IMAGES=(
    docker.io/bitnamilegacy/os-shell:12-debian-12-r48
    docker.io/bitnamilegacy/os-shell:12-debian-12-r51
    docker.io/bitnamilegacy/elasticsearch:8.17.4
    docker.io/bitnamilegacy/mongodb:6.0.13
)

# ingress-nginx images (registry.k8s.io). NOT pulled here — registry.k8s.io may be
# blocked in some networks; pull them yourself first, this only loads what's present.
#
# ⚠️ Loading these is NOT enough on its own: the upstream ingress-nginx deploy.yaml pins
# both images by DIGEST (`:v1.11.3@sha256:...`). `kind load docker-image` imports them
# under the TAG with a locally-computed digest, so the pinned digest never resolves and
# kubelet falls back to a registry pull -> 403 ImagePullBackOff on the certgen jobs.
# Strip the digests before applying (all three containers already use IfNotPresent).
# Pick the flavour that matches the cluster:
#   .../provider/kind/deploy.yaml       -> single-node (hostPort, localhost:8081)
#   .../provider/baremetal/deploy.yaml  -> prod mirror (Service patched to LoadBalancer)
#   curl -sSL -o ingress-nginx.yaml \
#     https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/<flavour>/deploy.yaml
#   sed -i '' -E 's|(image: registry\.k8s\.io/[^@]*)@sha256:[0-9a-f]{64}|\1|' ingress-nginx.yaml
#   kubectl apply -f ingress-nginx.yaml
INGRESS_IMAGES=(
    registry.k8s.io/ingress-nginx/controller:v1.11.3
    registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.4
)

# MetalLB images (quay.io) — needed by the prod-mirror cluster (kind-cluster-ha.yaml),
# which uses a real LoadBalancer VIP instead of extraPortMappings. Harmless for the
# single-node cluster, which never installs MetalLB.
METALLB_IMAGES=(
    quay.io/metallb/controller:v0.14.8
    quay.io/metallb/speaker:v0.14.8
)

# Pull only what's MISSING, and never abort the run on a pull failure: quay.io and
# registry.k8s.io are 403-blocked on some networks, and an already-loaded local copy is
# just as good. Anything still absent afterwards is reported and skipped at load time,
# so you can pull it yourself and re-run.
ensure_local() {
    local img="$1"
    if docker image inspect "$img" >/dev/null 2>&1; then
        echo "   already local: $img"
        return 0
    fi
    echo "   docker pull $img"
    if docker pull "$img" >/dev/null 2>&1; then
        return 0
    fi
    echo "   ⚠️  PULL FAILED (registry blocked?) — pull it yourself, then re-run: $img"
    return 1
}

echo ">> Ensuring images are on the host (avoids the throttled in-cluster pulls)..."
PRESENT=()
for img in "${GRAVITEE_IMAGES[@]}" "${BITNAMI_IMAGES[@]}" "${INGRESS_IMAGES[@]}" "${METALLB_IMAGES[@]}"; do
    if ensure_local "$img"; then
        PRESENT+=("$img")
    fi
done

echo ">> Loading ${#PRESENT[@]} image(s) into kind cluster '$CLUSTER'..."
kind load docker-image "${PRESENT[@]}" --name "$CLUSTER"

echo ">> Done. Images available on the kind node(s)."
