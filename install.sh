#!/usr/bin/env bash
# Install sites-deploy to /usr/local/bin/sites-deploy
set -euo pipefail

URL="${SITES_DEPLOY_URL:-https://raw.githubusercontent.com/expashka/deploy/main/sites-deploy}"
DEST="${SITES_DEPLOY_DEST:-/usr/local/bin/sites-deploy}"

if [[ "$EUID" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "→ Downloading from $URL"
TMP="$(mktemp)"
curl -fsSL "$URL" -o "$TMP"
chmod +x "$TMP"

# Quick sanity check
head -1 "$TMP" | grep -q '^#!/usr/bin/env bash' || {
  echo "Downloaded file doesn't look like a bash script — aborting" >&2
  rm -f "$TMP"
  exit 1
}

$SUDO mv "$TMP" "$DEST"
echo "→ Installed: $DEST"
"$DEST" --version
echo
echo "Done. In any project, add a .deploy.env and run: sites-deploy"
