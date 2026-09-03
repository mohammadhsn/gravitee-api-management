#!/usr/bin/env bash
#
# Mirror every image the APIM chart needs into an internal registry, for an
# AIR-GAPPED prod cluster. Pairs with helm/prod/values-airgap.yaml, which repoints the
# chart at $REGISTRY using exactly the tags produced here.
#
# The list below is the COMPLETE set — it was derived from, and must stay in sync with:
#   helm template apim helm/ -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml \
#     | grep -oE 'image: "?[^"]+'
# Re-run that after any chart bump and reconcile.
#
# Three modes, depending on how isolated the cluster is:
#
#   ./mirror-images.sh mirror  registry.internal      # one host reaches BOTH internet + registry
#   ./mirror-images.sh bundle  /media/usb/apim.tar    # OUTSIDE: pull + save to one tarball
#   ./mirror-images.sh push    registry.internal /media/usb/apim.tar   # INSIDE: load + push
#
set -euo pipefail

MODE="${1:-}"

# ── Source images (public) -> destination path/tag (inside the internal registry) ──
# Left of '=' is what we pull; right is the repo:tag we publish. They match except for
# apim-portal-ui, which upstream only ships as ':latest' — an unpinnable moving target.
# We pin it to 4.11.6 in the internal registry so prod is reproducible; the internal
# registry becomes the source of truth for that component.
IMAGES=(
    "graviteeio/apim-management-api:4.11.6=graviteeio/apim-management-api:4.11.6"
    "graviteeio/apim-gateway:4.11.6=graviteeio/apim-gateway:4.11.6"
    "graviteeio/apim-management-ui:4.11.6=graviteeio/apim-management-ui:4.11.6"
    "graviteeio/apim-portal-ui:latest=graviteeio/apim-portal-ui:4.11.6"
    "docker.io/bitnamilegacy/mongodb:6.0.13=bitnamilegacy/mongodb:6.0.13"
    "docker.io/bitnamilegacy/elasticsearch:8.17.4=bitnamilegacy/elasticsearch:8.17.4"
    "docker.io/bitnamilegacy/os-shell:12-debian-12-r48=bitnamilegacy/os-shell:12-debian-12-r48"
    "docker.io/bitnamilegacy/os-shell:12-debian-12-r51=bitnamilegacy/os-shell:12-debian-12-r51"
    # ── Observability companion chart (helm/observability/) ──
    # Only needed if you deploy that release. Set its global.imageRegistry to the same
    # host and these paths line up (it prefixes the host, keeping the path intact).
    # Logstash is included even though it defaults to disabled, so the bundle is complete
    # if you later switch it on inside the air gap where you cannot pull.
    "prom/prometheus:v2.53.2=prom/prometheus:v2.53.2"
    "grafana/grafana:11.3.1=grafana/grafana:11.3.1"
    "docker.elastic.co/kibana/kibana:8.12.0=docker.elastic.co/kibana/kibana:8.12.0"
    "docker.elastic.co/logstash/logstash:8.17.2=docker.elastic.co/logstash/logstash:8.17.2"
    "docker.elastic.co/beats/filebeat:8.17.2=docker.elastic.co/beats/filebeat:8.17.2"
    # ── Test backend (helm/test-backend/) ──
    # Optional diagnostic fixture. Upstream only publishes ':latest', so it is retagged
    # to 1.0.0 in the internal registry -- same reason as apim-portal-ui: an air-gapped
    # install must not depend on a moving tag. Build it first with
    # docker/quick-setup/keycloak/build-service-b.sh if it is not on the host.
    "docker.io/mohammadhsn/service-b:latest=mohammadhsn/service-b:1.0.0"
)

src_of() { echo "${1%%=*}"; }
dst_of() { echo "${1##*=}"; }

usage() {
    sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

# Pull only what's missing. --platform is pinned so a mixed-arch workstation (e.g. Apple
# Silicon) cannot quietly bundle arm64 images for amd64 prod nodes — the single most
# common way an air-gap mirror ends up unusable.
PLATFORM="${PLATFORM:-linux/amd64}"
pull_all() {
    echo ">> Pulling ${#IMAGES[@]} images for platform $PLATFORM ..."
    for pair in "${IMAGES[@]}"; do
        local src; src="$(src_of "$pair")"
        echo "   $src"
        docker pull --platform "$PLATFORM" "$src"
    done
}

verify_arch() {
    echo ">> Verifying architecture (must all be ${PLATFORM##*/}):"
    local bad=0
    for pair in "${IMAGES[@]}"; do
        local src arch; src="$(src_of "$pair")"
        arch="$(docker image inspect "$src" --format '{{.Architecture}}' 2>/dev/null || echo MISSING)"
        printf '   %-58s %s\n' "$src" "$arch"
        [ "$arch" = "${PLATFORM##*/}" ] || bad=1
    done
    [ "$bad" = 0 ] || { echo "   ✗ architecture mismatch — prod nodes will fail with 'exec format error'"; exit 1; }
}

case "$MODE" in
mirror)
    REGISTRY="${2:?usage: mirror <registry-host[:port]>}"
    pull_all
    verify_arch
    echo ">> Retagging + pushing to $REGISTRY ..."
    for pair in "${IMAGES[@]}"; do
        src="$(src_of "$pair")"; dst="$REGISTRY/$(dst_of "$pair")"
        docker tag "$src" "$dst"
        echo "   push $dst"
        docker push "$dst"
    done
    echo ">> Done. Set global.imageRegistry + the 4 image.repository values to $REGISTRY"
    ;;
bundle)
    TARBALL="${2:?usage: bundle <output.tar>}"
    pull_all
    verify_arch
    echo ">> Saving $((${#IMAGES[@]})) images -> $TARBALL (this is large, ~3-4GB)"
    docker save -o "$TARBALL" $(for p in "${IMAGES[@]}"; do src_of "$p"; done)
    echo ">> Done. Carry $TARBALL inside, then: ./mirror-images.sh push <registry> $TARBALL"
    echo "   Checksum it first:  shasum -a 256 $TARBALL"
    ;;
push)
    REGISTRY="${2:?usage: push <registry-host[:port]> <input.tar>}"
    TARBALL="${3:?usage: push <registry-host[:port]> <input.tar>}"
    echo ">> Loading $TARBALL ..."
    docker load -i "$TARBALL"
    echo ">> Retagging + pushing to $REGISTRY ..."
    for pair in "${IMAGES[@]}"; do
        src="$(src_of "$pair")"; dst="$REGISTRY/$(dst_of "$pair")"
        docker tag "$src" "$dst"
        echo "   push $dst"
        docker push "$dst"
    done
    echo ">> Done."
    ;;
*)
    usage
    ;;
esac
