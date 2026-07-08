#!/usr/bin/env bash
#
# Export a clean, minimal, ZERO-STATE bundle of this stack for sharing / VM deploy.
#
# The repo is the single source of truth: this copies only the run-essential files
# plus the bundle-owned overlay (README/instructs/spec) into a fresh target dir.
# Re-run anytime after changing the source — the target is rebuilt from scratch,
# so there is no drift and no runtime state leaks into the bundle.
#
#   ./export-bundle.sh                 # -> ~/Desktop/gravitee-keycloak
#   ./export-bundle.sh /path/to/out    # custom target
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$HOME/Desktop/gravitee-keycloak}"

# Safety: never operate on an empty/root target.
case "$TARGET" in ""|"/"|"$HOME") echo "Refusing to use target '$TARGET'." >&2; exit 1;; esac

# Run-essential files/dirs (the minimum needed to `docker compose up` on a VM).
# NOTE: intentionally excluded — build tooling (build-*.sh, buildx-lib.sh) and
# service-b/ source (the image is pulled from the registry), CLAUDE.md,
# EDGE_PROXY_TRADEOFFS.md, .env (ships .env.dist only), .logs/ (runtime).
FILES=(
    docker-compose.yml
    .env.dist
    secured-api.json
    download-plugins-ext.sh
    conf
    realm/realm-gio.json
    elk
    prometheus
    grafana
)

echo ">> Exporting zero-state bundle"
echo "   from : $SRC"
echo "   to   : $TARGET"
rm -rf "$TARGET"
mkdir -p "$TARGET"

for item in "${FILES[@]}"; do
    src="$SRC/$item"; dst="$TARGET/$item"
    if [ -d "$src" ]; then
        mkdir -p "$dst"
        rsync -a --exclude='.DS_Store' --exclude='CLAUDE.md' "$src/" "$dst/"
    elif [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    else
        echo "   WARNING: missing source '$item' — skipped" >&2
    fi
done

# Bundle-owned overlay (canonical copies live in the repo): README.md, instructs, spec.yaml
rsync -a --exclude='.DS_Store' "$SRC/export-overlay/" "$TARGET/"

echo ">> Done. Bundle contents:"
( cd "$TARGET" && find . -type f | LC_ALL=C sort | sed 's|^\./|   |' )
