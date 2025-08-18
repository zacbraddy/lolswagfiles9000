#!/bin/bash

echo "🚀 Installing JetBrains Toolbox..."

# Function to get latest version info
get_latest_version() {
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is required but not installed. Installing curl..."
        sudo apt-get update && sudo apt-get install -y curl
    fi

    # Get the latest version information from JetBrains API
    local VERSION_INFO
    VERSION_INFO=$(curl -sL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release")

    # Extract version and download URL using grep and cut
    local VERSION
    VERSION=$(echo "$VERSION_INFO" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

    local DOWNLOAD_URL
    DOWNLOAD_URL=$(echo "$VERSION_INFO" | grep -o '"linux":{"link":"[^"]*"' | cut -d'"' -f6)

    if [ -z "$DOWNLOAD_URL" ] || [ -z "$VERSION" ]; then
        echo "Error: Failed to get latest version information"
        echo "Falling back to manual version detection..."

        # Fallback: try to get the latest version from the downloads page
        local FALLBACK_INFO
        FALLBACK_INFO=$(curl -sL "https://www.jetbrains.com/toolbox/download/")

        # Extract version from the download page
        VERSION=$(echo "$FALLBACK_INFO" | grep -o 'jetbrains-toolbox-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/jetbrains-toolbox-//')

        if [ -z "$VERSION" ]; then
            echo "Error: Could not determine latest version"
            exit 1
        fi

        # Construct download URL
        DOWNLOAD_URL="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz"
    fi

    echo "$DOWNLOAD_URL|$VERSION"
}

VERSION_INFO=$(get_latest_version)
DOWNLOAD_URL=$(echo "$VERSION_INFO" | cut -d'|' -f1)
VERSION=$(echo "$VERSION_INFO" | cut -d'|' -f2)

echo "Latest version: $VERSION"
echo "Downloading from: $DOWNLOAD_URL"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download JetBrains Toolbox
echo "📥 Downloading JetBrains Toolbox..."
if ! curl -L "$DOWNLOAD_URL" -o toolbox.tar.gz; then
    echo "Error: Failed to download JetBrains Toolbox"
    exit 1
fi

# Extract the archive
echo "📦 Extracting..."
if ! tar -xzf toolbox.tar.gz; then
    echo "Error: Failed to extract archive"
    exit 1
fi

# Move to applications directory
echo "📂 Installing..."
sudo mv jetbrains-toolbox-*/jetbrains-toolbox /usr/local/bin/

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Create desktop entry
echo "Creating desktop shortcut..."
DESKTOP_FILE="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=JetBrains Toolbox
Comment=JetBrains Toolbox App
Exec=/usr/local/bin/jetbrains-toolbox
Icon=jetbrains-toolbox
Terminal=false
Categories=Development;IDE;
EOL

# Update desktop database
echo "Updating desktop database..."
update-desktop-database "$HOME/.local/share/applications"

echo "✅ JetBrains Toolbox installed successfully!"
echo "   You can now launch it from your applications menu."
