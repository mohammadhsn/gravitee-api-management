#!/usr/bin/env bash
#
# Build the Developer Portal UI image used by docker-compose.yml (portal_ui service).
#
# The portal is the Angular app in gravitee-apim-portal-webui/. Its Dockerfile
# (docker/Dockerfile) only PACKAGES a prebuilt ./dist — it does not compile the
# app. So this script:
#   1. Compiles the front end into ./dist using a pinned node:20 container
#      (host node version is irrelevant; same result on mac/linux). The compiled
#      ./dist is just static JS/HTML — architecture-NEUTRAL — so it is built once.
#   2. buildx-builds the nginx image that serves ./dist, optionally for multiple
#      architectures (only the nginx base image differs per arch).
#
# Cross-platform: runs on macOS and Linux; only Docker is required (no host node).
#
# Local single-arch build:
#   ./build-portal-ui.sh
#   PLATFORM=linux/amd64 ./build-portal-ui.sh
#
# Multi-arch build + push:
#   docker login <registry>
#   IMAGE=docker.io/youruser/gravitee-portal-ui-fa:1.0 PLATFORM=linux/amd64,linux/arm64 PUSH=1 ./build-portal-ui.sh
#
#   SKIP_COMPILE=1 ./build-portal-ui.sh    # reuse an existing ./dist, only build/push the image
#   BUILD_SCRIPT=build:prod ./build-...sh  # use a different yarn build script
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=buildx-lib.sh
. "$SCRIPT_DIR/buildx-lib.sh"

# keycloak dir -> quick-setup -> docker -> repo root -> portal module
MODULE="$(cd "$SCRIPT_DIR/../../../gravitee-apim-portal-webui" && pwd)"

IMAGE="${IMAGE:-gravitee-portal-ui-fa:latest}"
NODE_IMAGE="${NODE_IMAGE:-node:20}"
BUILD_SCRIPT="${BUILD_SCRIPT:-build}"
SKIP_COMPILE="${SKIP_COMPILE:-}"

[ -f "$MODULE/docker/Dockerfile" ] || { echo "ERROR: portal module not found at $MODULE" >&2; exit 1; }

echo ">> Portal module: $MODULE"

# ── 1. Compile the Angular app into ./dist (architecture-neutral; build once) ──
if [ -z "$SKIP_COMPILE" ]; then
    echo ">> Compiling front end with $NODE_IMAGE (yarn $BUILD_SCRIPT) ..."
    docker run --rm \
        -v "$MODULE":/app -w /app \
        -e COREPACK_HOME=/tmp/corepack \
        -e YARN_CACHE_FOLDER=/tmp/yarn \
        "$NODE_IMAGE" sh -euc "
            corepack enable
            yarn install
            yarn $BUILD_SCRIPT
            chown -R $(id -u):$(id -g) dist node_modules .yarn 2>/dev/null || true
        "
else
    echo ">> SKIP_COMPILE set — reusing existing $MODULE/dist"
fi

[ -d "$MODULE/dist" ] || { echo "ERROR: $MODULE/dist not found after compile step." >&2; exit 1; }

# ── 2. Build (and optionally push, multi-arch) the image that serves ./dist ──
buildx_image "$IMAGE" "$MODULE" -f "$MODULE/docker/Dockerfile"
