#!/usr/bin/env bash

# setup-filestore.sh - Initialize filestore structure and symlinks

set -e

FILESTORE_DIR="$HOME/filestore"
STANDARD_DIRS=("Documents" "Pictures" "Downloads")

echo "🗂️  Setting up filestore structure..."

# Create the main filestore directory
mkdir -p "$FILESTORE_DIR"

# Process each standard directory
for dir in "${STANDARD_DIRS[@]}"; do
    standard_path="$HOME/$dir"
    filestore_path="$FILESTORE_DIR/$dir"
    
    echo "📁 Processing $dir..."
    
    # Create the directory in filestore if it doesn't exist
    mkdir -p "$filestore_path"
    
    # Handle existing directory
    if [ -e "$standard_path" ]; then
        if [ -L "$standard_path" ]; then
            # Already a symlink, check if it points to the right place
            if [ "$(readlink "$standard_path")" = "$filestore_path" ]; then
                echo "✅ $dir already correctly symlinked"
                continue
            else
                echo "🔄 Updating existing symlink for $dir"
                rm "$standard_path"
            fi
        elif [ -d "$standard_path" ]; then
            echo "📦 Moving existing $dir contents to filestore"
            # Move contents to filestore, merge if needed
            if [ "$(ls -A "$standard_path" 2>/dev/null)" ]; then
                cp -r "$standard_path"/* "$filestore_path"/ 2>/dev/null || true
                cp -r "$standard_path"/.[^.]* "$filestore_path"/ 2>/dev/null || true
            fi
            rm -rf "$standard_path"
        else
            echo "🗑️  Removing existing file at $standard_path"
            rm -f "$standard_path"
        fi
    fi
    
    # Create the symlink
    ln -s "$filestore_path" "$standard_path"
    echo "✅ Created symlink: $standard_path -> $filestore_path"
done

# Create config directory for filestore
mkdir -p "$HOME/.config/filestore"

# Create exclusions file
cat > "$HOME/.config/filestore/exclusions.txt" << 'EOF'
# Filestore exclusions - patterns to exclude from sync
- .DS_Store
- .Thumbs.db
- *.tmp
- *.temp
- *~
- .cache/**
- .thumbnails/**
- node_modules/**
- __pycache__/**
- *.log
- .git/**
EOF

echo "✅ Filestore structure initialized successfully!"
echo "📂 Filestore location: $FILESTORE_DIR"
echo "🔗 Standard directories now symlinked to filestore"
echo "⚙️  Exclusions configured at ~/.config/filestore/exclusions.txt"