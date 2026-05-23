#!/usr/bin/env bash
# Install sites-deploy to /usr/local/bin/sites-deploy
set -euo pipefail

URL="${SITES_DEPLOY_URL:-https://raw.githubusercontent.com/expashka/deploy/main/sites-deploy}"
DEST="${SITES_DEPLOY_DEST:-/usr/local/bin/sites-deploy}"

DEPLOY_URL="${DEPLOY_URL:-https://raw.githubusercontent.com/expashka/deploy/main/deploy}"
DEPLOY_DEST="${DEPLOY_DEST:-/usr/local/bin/deploy}"

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

echo "→ Downloading deploy from $DEPLOY_URL"
TMP2="$(mktemp)"
curl -fsSL "$DEPLOY_URL" -o "$TMP2"
chmod +x "$TMP2"
head -1 "$TMP2" | grep -q '^#!/usr/bin/env bash' || {
  echo "Downloaded file doesn't look like a bash script — aborting" >&2
  rm -f "$TMP2"
  exit 1
}
$SUDO mv "$TMP2" "$DEPLOY_DEST"
echo "→ Installed: $DEPLOY_DEST"

echo
echo "Done. Run 'deploy' to pick a site interactively, or 'sites-deploy' from a project root."
