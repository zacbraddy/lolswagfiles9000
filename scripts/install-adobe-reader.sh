#!/usr/bin/env bash
set -euo pipefail

DEB_URL="https://ardownload2.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb"
DEB_FILE="/tmp/AdbeRdr9.5.5-1_i386linux_enu.deb"
PKG_NAME="adobereader-enu"

if dpkg -l | grep -qi "$PKG_NAME"; then
  echo "Adobe Reader already installed."
  exit 0
fi

echo "Downloading Adobe Reader .deb..."
curl -L "$DEB_URL" -o "$DEB_FILE"
echo "Installing Adobe Reader..."
sudo dpkg -i "$DEB_FILE" || sudo apt-get -f install -y
