#!/bin/bash
set -e

# Configurable via environment variables or .env file
MINIFLUX_DIR="${MINIFLUX_DIR:-$HOME/Desktop/miniflux}"
DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/ctrl-i/miniflux-with-descriptions:latest}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/arm64/v8}"
DOCKERFILE="${DOCKERFILE:-packaging/docker/alpine/Dockerfile}"
PUSH="${PUSH:-false}"

# Load .env if it exists (for private settings - NOT committed to git)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

PATCHES_DIR="$SCRIPT_DIR/patches"

echo "=== Miniflux Custom Build ==="
echo "Source:  $MINIFLUX_DIR"
echo "Image:   $DOCKER_IMAGE"
echo "Platform: $DOCKER_PLATFORM"
echo "Push:    $PUSH"
echo ""

# Check miniflux source exists
if [ ! -d "$MINIFLUX_DIR" ]; then
    echo "Error: Miniflux source not found at $MINIFLUX_DIR"
    echo "Run: git clone https://github.com/miniflux/v2.git $MINIFLUX_DIR"
    exit 1
fi

# Copy patched files into miniflux source
echo "Applying patches..."
cp "$PATCHES_DIR/entry_query_builder.go" "$MINIFLUX_DIR/internal/storage/entry_query_builder.go"
cp "$PATCHES_DIR/functions.go" "$MINIFLUX_DIR/internal/template/functions.go"
cp "$PATCHES_DIR/item_meta.html" "$MINIFLUX_DIR/internal/template/templates/common/item_meta.html"

# Append preview CSS to common.css (don't replace - preserves upstream changes)
# First remove any previously appended preview styles
sed -i '/=== Entry preview and thumbnail styles (appended by miniflux-with-descriptions)/,$ d' "$MINIFLUX_DIR/internal/ui/static/css/common.css"
cat "$PATCHES_DIR/preview.css" >> "$MINIFLUX_DIR/internal/ui/static/css/common.css"

echo "Patches applied."

# Build
echo "Building..."
cd "$MINIFLUX_DIR"

PUSH_FLAG=""
if [ "$PUSH" = "true" ]; then
    PUSH_FLAG="--push"
fi

docker buildx build $PUSH_FLAG --platform "$DOCKER_PLATFORM" \
    -f "$DOCKERFILE" \
    --tag "$DOCKER_IMAGE" .

echo ""
echo "=== Build complete! ==="
if [ "$PUSH" = "true" ]; then
    echo "Pushed: $DOCKER_IMAGE"
else
    echo "Built:  $DOCKER_IMAGE"
fi