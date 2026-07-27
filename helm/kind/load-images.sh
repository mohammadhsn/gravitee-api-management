#!/usr/bin/env bash
#
# Make all images the chart needs available inside the kind cluster WITHOUT the
# (slow / 403-throttled) in-cluster pulls. kind has no native image-preload in its
# cluster config, so this is the recorded "load step" — run it after creating the
# cluster and before `helm install`.
#
#   helm/kind/load-images.sh                 # cluster: gravitee-apim
#   helm/kind/load-images.sh my-cluster
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
INGRESS_IMAGES=(
    registry.k8s.io/ingress-nginx/controller:v1.11.3
    registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.4
)

# MetalLB images (quay.io) — needed only by the prod-mirror cluster (kind-cluster-prod.yaml),
# which uses a real LoadBalancer VIP instead of extraPortMappings. quay.io is usually
# reachable; pulled here like the Bitnami set, then loaded. Harmless for the other clusters.
METALLB_IMAGES=(
    quay.io/metallb/controller:v0.14.8
    quay.io/metallb/speaker:v0.14.8
)

echo ">> Pulling Bitnami + MetalLB images on the host (avoids the throttled in-cluster pulls)..."
for img in "${BITNAMI_IMAGES[@]}" "${METALLB_IMAGES[@]}"; do
    echo "   docker pull $img"
    docker pull "$img" >/dev/null
done

echo ">> Loading Gravitee + Bitnami + MetalLB images into kind cluster '$CLUSTER'..."
kind load docker-image "${GRAVITEE_IMAGES[@]}" "${BITNAMI_IMAGES[@]}" "${METALLB_IMAGES[@]}" --name "$CLUSTER"

echo ">> Loading ingress-nginx images (only those already pulled locally)..."
for img in "${INGRESS_IMAGES[@]}"; do
    if docker image inspect "$img" >/dev/null 2>&1; then
        kind load docker-image "$img" --name "$CLUSTER"
    else
        echo "   NOT on host (pull it yourself if registry.k8s.io is blocked): $img"
    fi
done

echo ">> Done. Images available on the kind node."
