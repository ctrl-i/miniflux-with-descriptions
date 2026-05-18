# Miniflux with Descriptions

Content preview and thumbnail patch for Miniflux entry list pages.

Adds a content preview and first-image thumbnail to Miniflux entry list pages.

## What it does

- Shows the first few lines of each entry's content below the title in list views
- Shows the first image from the entry as a thumbnail on the right side
- Works on all list pages: unread, feed entries, category entries, starred, history, search

## How it works

Patches only 4 files (3 replaced, 1 appended):

| File | Change |
|------|--------|
| `internal/storage/entry_query_builder.go` | `WithoutContent()` now returns `LEFT(e.content, 3000)` instead of empty string — enough for preview without full content overhead |
| `internal/template/functions.go` | Adds `firstImageURL` (HTML tokenizer to find first `<img>`) and `truncateHTML` (strip tags + truncate) template functions |
| `internal/template/templates/common/item_meta.html` | Adds preview section with thumbnail and text between the feed info and action buttons |
| `internal/ui/static/css/common.css` | Appends preview/thumbnail CSS (does not replace the file) |

## Setup (one-time)

1. Clone this repo:
   ```bash
   git clone https://github.com/ctrl-i/miniflux-with-descriptions.git ~/Desktop/miniflux-with-descriptions
   ```

2. Copy `.env.example` to `.env` and fill in your details:
   ```bash
   cp .env.example .env
   nano .env
   ```
   
   Your `.env` will look like:
   ```
   MINIFLUX_DIR="$HOME/Desktop/miniflux"
   DOCKER_IMAGE="ghcr.io/ctrl-i/miniflux-with-descriptions:latest"
   DOCKER_PLATFORM="linux/arm64/v8"
   PUSH="true"
   ```

3. Make build.sh executable:
   ```bash
   chmod +x build.sh
   ```

4. Enable GitHub Container Registry for your repo (one-time):
   - Go to your repo on GitHub → **Settings** → **General**
   - Scroll to **Packages** → ensure "Public" is selected
   - Generate a Personal Access Token (classic) with `write:packages` scope:
    GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token**
   - Check the `write:packages` scope
   - Save the token somewhere safe

## Build (every time)

```bash
# Install Docker if not already installed
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Login to GitHub Container Registry (use your GitHub username and the PAT as password)
echo YOUR_GITHUB_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Get fresh miniflux source
git clone https://github.com/miniflux/v2.git ~/Desktop/miniflux

# Create buildx builder for cross-platform
docker buildx create --use

# Build and push
cd ~/Desktop/miniflux-with-descriptions
./build.sh

# Cleanup
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo apt autoremove -y
sudo rm -rf /var/lib/docker /var/lib/containerd
rm -rf ~/Desktop/miniflux
```

## Docker Compose (on your server)

Your docker-compose.yml references the image from ghcr.io:

```yaml
services:
  miniflux:
    image: ghcr.io/ctrl-i/miniflux-with-descriptions:latest
    # ... rest of your miniflux config
```

Then just `docker compose pull && docker compose up -d` to update.

## When a new Miniflux version comes out

Just re-run the build steps above. Fresh source is pulled and patches are applied on top.

If a future Miniflux update changes one of the patched files in an incompatible way, the build will fail with a Go compilation error. To fix:
1. Check which file failed
2. Look at the upstream changes to that file  
3. Update the corresponding file in `patches/`

## No Miniflux settings needed

No configuration changes are needed in Miniflux itself. The preview is always shown when content is available. If an entry has no content or no images, it gracefully shows nothing.
