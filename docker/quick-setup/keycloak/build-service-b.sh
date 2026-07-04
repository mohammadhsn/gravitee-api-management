#!/usr/bin/env bash
#
# Build the service-b demo backend image.
#
# Cross-platform: runs on macOS and Linux; only Docker is required.
#
# Local single-arch build (loads into your local docker):
#   ./build-service-b.sh
#   PLATFORM=linux/amd64 ./build-service-b.sh        # cross-build one arch (still local)
#
# Multi-arch build + push to a registry (the only way to ship both arches):
#   docker login <registry>
#   IMAGE=docker.io/youruser/service-b:1.0 PLATFORM=linux/amd64,linux/arm64 PUSH=1 ./build-service-b.sh
#
# Notes:
#   * A multi-arch image CANNOT be loaded into the local daemon — PUSH=1 is required.
#   * IMAGE must be a registry-qualified tag when pushing.
#   * Needs QEMU/binfmt for the non-native arch (Docker Desktop ships it; on bare
#     Linux run once: docker run --privileged --rm tonistiigi/binfmt --install all).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=buildx-lib.sh
. "$SCRIPT_DIR/buildx-lib.sh"

IMAGE="${IMAGE:-service-b:latest}"
CONTEXT="$SCRIPT_DIR/service-b"

[ -f "$CONTEXT/Dockerfile" ] || { echo "ERROR: $CONTEXT/Dockerfile not found." >&2; exit 1; }

buildx_image "$IMAGE" "$CONTEXT"
