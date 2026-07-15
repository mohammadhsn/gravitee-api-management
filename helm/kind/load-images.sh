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

echo ">> Pulling Bitnami images on the host (avoids the throttled in-cluster pulls)..."
for img in "${BITNAMI_IMAGES[@]}"; do
    echo "   docker pull $img"
    docker pull "$img" >/dev/null
done

echo ">> Loading all images into kind cluster '$CLUSTER'..."
kind load docker-image "${GRAVITEE_IMAGES[@]}" "${BITNAMI_IMAGES[@]}" --name "$CLUSTER"

echo ">> Done. Images available on the kind node."
