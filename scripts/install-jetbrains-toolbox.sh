#!/bin/bash

echo "🚀 Installing JetBrains Toolbox..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download JetBrains Toolbox
echo "📥 Downloading JetBrains Toolbox..."
curl -L "https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.28.1.15219.tar.gz" -o toolbox.tar.gz

# Extract the archive
echo "📦 Extracting..."
tar -xzf toolbox.tar.gz

# Move to applications directory
echo "📂 Installing..."
sudo mv jetbrains-toolbox-*/jetbrains-toolbox /usr/local/bin/

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Create desktop entry
cat > ~/.local/share/applications/jetbrains-toolbox.desktop << EOL
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

echo "✅ JetBrains Toolbox installed successfully!"
echo "   You can now launch it from your applications menu."
