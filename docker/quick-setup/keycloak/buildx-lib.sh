#!/usr/bin/env bash
#
# Shared buildx helper for the image build scripts. Source it, then call:
#   buildx_image <image-tag> <context-dir> [extra docker-build args...]
#
# Behaviour is driven by env vars:
#   PLATFORM   target platform(s), e.g. "linux/amd64" or "linux/amd64,linux/arm64"
#              (default: host architecture)
#   PUSH       set to non-empty to --push to a registry instead of --load locally
#   BUILDER    buildx builder name to create/use for multi-arch or push
#              (default: gravitee-multiarch)
#
# Rules enforced:
#   * Multi-arch (comma in PLATFORM) requires PUSH — a local daemon can't hold a
#     multi-arch manifest. We fail fast with a clear message otherwise.
#   * Multi-arch / push use a docker-container builder (the default `docker`
#     driver can't emit a manifest list); it's created on demand.

PLATFORM="${PLATFORM:-}"
PUSH="${PUSH:-}"
BUILDER="${BUILDER:-gravitee-multiarch}"

_is_multi() { case "$1" in *,*) return 0 ;; *) return 1 ;; esac; }

buildx_image() {
    image="$1"; context="$2"; shift 2   # remaining "$@" = extra docker build args

    if _is_multi "$PLATFORM" && [ -z "$PUSH" ]; then
        echo "ERROR: multi-platform build ($PLATFORM) cannot be loaded locally." >&2
        echo "       Set PUSH=1 and use a registry-qualified IMAGE to push a multi-arch manifest." >&2
        exit 1
    fi

    output="--load"
    [ -n "$PUSH" ] && output="--push"

    platform_flag=""
    [ -n "$PLATFORM" ] && platform_flag="--platform $PLATFORM"

    # The default 'docker' driver can't produce manifest lists; switch to a
    # docker-container builder whenever we go multi-arch or push.
    builder_flag=""
    if _is_multi "$PLATFORM" || [ -n "$PUSH" ]; then
        if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
            echo ">> creating buildx builder '$BUILDER' (docker-container driver)"
            docker buildx create --name "$BUILDER" --driver docker-container --bootstrap >/dev/null
        fi
        builder_flag="--builder $BUILDER"
    fi

    echo ">> Building $image"
    echo "   context : $context"
    echo "   platform: ${PLATFORM:-<host: $(uname -m)>}"
    echo "   output  : ${PUSH:+push to registry}${PUSH:-load into local docker}"

    # Word-splitting on the *_flag vars is intentional (they carry flags).
    # shellcheck disable=SC2086
    docker buildx build $builder_flag $platform_flag $output -t "$image" "$@" "$context"

    echo ">> Done. Image: $image"
}
