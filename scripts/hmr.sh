#!/usr/bin/env bash
set -e

SECRETS_FILE="nix/secrets/secrets.yaml"
SOPS_CONFIG="nix/secrets/.sops.yaml"
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# Setup directories
mkdir -p "$HOME/.local/bin" \
         "$HOME/.local/state/home-manager/gcroots"

# Verify nix commands are available
if ! command -v nix-build >/dev/null; then
    echo "❌ Nix commands not found in PATH" >&2
    echo "Please ensure Nix is properly installed and in your PATH" >&2
    exit 1
fi

echo "===== HMR STARTED ====="

# Cleanup existing files
echo "===== CLEANING EXISTING FILES ====="
echo "Removing ~/.zshrc symlink..."
if [ -f "$HOME/.zshrc" ] && ! [ -L "$HOME/.zshrc" ]; then
    echo "❌ .zshrc exists as a regular file - this should never happen!"
    echo "Please manually remove $HOME/.zshrc and run hmr again"
    exit 1
fi
[ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"

echo "Removing ~/.p10k.zsh symlink..."
if [ -f "$HOME/.p10k.zsh" ] && ! [ -L "$HOME/.p10k.zsh" ]; then
    echo "❌ .p10k.zsh exists as a regular file - this should never happen!"
    echo "Please manually remove $HOME/.p10k.zsh and run hmr again"
    exit 1
fi
[ -L "$HOME/.p10k.zsh" ] && rm "$HOME/.p10k.zsh"

# Secrets verification
echo "===== VERIFYING SECRETS ====="
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "❌ Age key file not found at $AGE_KEY_FILE"
    echo "Run 'just secrets-setup-key' to set up encryption keys"
    exit 1
fi

if SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" sops -d --config "$SOPS_CONFIG" "$SECRETS_FILE" 2>/dev/null | grep -q '^{}$'; then
    echo "❌ secrets.yaml is empty"
    echo "Run 'just secrets-add' to add required secrets"
    exit 1
fi

# Fix flatpak fusermount3 path for Pop!_OS
echo "===== FIXING FLATPAK FUSERMOUNT3 PATH ====="
if [ ! -f "/run/wrappers/bin/fusermount3" ] && [ -f "/usr/bin/fusermount3" ]; then
    echo "Creating fusermount3 symlink for flatpak compatibility..."
    sudo mkdir -p /run/wrappers/bin
    sudo ln -sf /usr/bin/fusermount3 /run/wrappers/bin/fusermount3
    echo "✅ fusermount3 symlink created"
else
    echo "✅ fusermount3 already configured"
fi

# Run Home Manager - let it handle all the symlinking automatically
echo "===== RUNNING HOME MANAGER ====="
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

NIX_CONFIG="experimental-features = nix-command flakes" \
nix run home-manager/master -- switch \
    --flake "/home/zacbraddy/Projects/Personal/lolswagfiles9000#zacbraddy" \
    --show-trace \
    -b ".backup-$BACKUP_TIMESTAMP" \
    "$@"

# Fix keyboard layout to British format
echo "===== FIXING KEYBOARD LAYOUT ====="
setxkbmap gb
echo "✅ Keyboard layout set to British (gb)"

# Install desktop entries for Nix applications
echo "===== INSTALLING DESKTOP ENTRIES ====="
NIX_APPLICATIONS_DIR="$HOME/.nix-profile/share/applications"
SYSTEM_APPLICATIONS_DIR="/usr/share/applications"

if [ -d "$NIX_APPLICATIONS_DIR" ]; then
    # Find all .desktop files in Nix applications directory
    find "$NIX_APPLICATIONS_DIR" -name "*.desktop" -type f | while read -r desktop_file; do
        filename=$(basename "$desktop_file")
        system_file="$SYSTEM_APPLICATIONS_DIR/$filename"

        # Check if file exists in system directory
        if [ ! -f "$system_file" ] || [ "$desktop_file" -nt "$system_file" ]; then
            echo "Installing desktop entry: $filename"
            sudo cp "$desktop_file" "$SYSTEM_APPLICATIONS_DIR/"
        fi
    done

    # Update desktop database
    sudo update-desktop-database
    echo "✅ Desktop entries updated"
else
    echo "⚠️  No Nix applications directory found at $NIX_APPLICATIONS_DIR"
fi

# Initialise Obsidian configuration
echo "===== INITIALISING OBSIDIAN CONFIGURATION ====="
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.obsidian"

# Create or update the obsidian configuration file (idempotent)
if [ ! -f "$HOME/.obsidian/config" ] || ! grep -q "^DOTFILES_PATH=$DOTFILES_DIR$" "$HOME/.obsidian/config"; then
    echo "DOTFILES_PATH=$DOTFILES_DIR" > "$HOME/.obsidian/config"
    echo "📝 Updated obsidian config with dotfiles path"
else
    echo "✅ Obsidian config already up to date"
fi

# Initialise the managed vaults file with dotfiles path
node "$DOTFILES_DIR/scripts/obsidian/vault-manager.js" init
echo "✅ Obsidian configuration initialised"

# Initialise Filestore
echo "===== INITIALISING FILESTORE ====="
if [ -f "$DOTFILES_DIR/scripts/backup/setup-filestore.sh" ]; then
    bash "$DOTFILES_DIR/scripts/backup/setup-filestore.sh"
    echo "✅ Filestore initialised"
else
    echo "⚠️  Filestore setup script not found"
fi

# Check rclone configuration for Google Drive
echo "===== CHECKING RCLONE CONFIGURATION ====="
if ! command -v rclone >/dev/null; then
    echo "⚠️  rclone not found - run Home Manager to install"
elif ! rclone listremotes | grep -q "gdrive:"; then
    echo "⚠️  Google Drive not configured in rclone"
    echo "💡 Run 'rclone config' to set up a remote called 'gdrive' for Google Drive"
    echo "   Then use 'bk-sync' to backup your filestore to Google Drive"
else
    echo "✅ Google Drive configured in rclone"
    echo "💡 Use 'bk-sync', 'bk-status', 'bk-pull' to manage your filestore"
fi

# Setup Claude symlinks
echo "===== SETTING UP CLAUDE SYMLINKS ====="
CLAUDE_DIR="$HOME/.claude"
DOTFILES_CLAUDE_DIR="$DOTFILES_DIR/claude"

# Ensure Claude directory exists
mkdir -p "$CLAUDE_DIR"

# Setup CLAUDE.md symlink
if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "✅ CLAUDE.md symlink already exists"
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "🔄 Backing up existing CLAUDE.md and creating symlink..."
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
    ln -s "$DOTFILES_CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "✅ CLAUDE.md symlink created"
else
    ln -s "$DOTFILES_CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "✅ CLAUDE.md symlink created"
fi

# Setup memory directory symlink
if [ -L "$CLAUDE_DIR/memory" ]; then
    echo "✅ memory symlink already exists"
elif [ -d "$CLAUDE_DIR/memory" ]; then
    echo "🔄 Backing up existing memory directory and creating symlink..."
    mv "$CLAUDE_DIR/memory" "$CLAUDE_DIR/memory.backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$DOTFILES_CLAUDE_DIR/memory"
    ln -s "$DOTFILES_CLAUDE_DIR/memory" "$CLAUDE_DIR/memory"
    echo "✅ memory symlink created"
else
    mkdir -p "$DOTFILES_CLAUDE_DIR/memory"
    ln -s "$DOTFILES_CLAUDE_DIR/memory" "$CLAUDE_DIR/memory"
    echo "✅ memory symlink created"
fi

# Setup npm configuration
echo "===== SETTING UP NPM CONFIGURATION ====="
DOTFILES_NPMRC="$DOTFILES_DIR/.npmrc"
USER_NPMRC="$HOME/.npmrc"

# Ensure npm directories exist
mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/node_modules"

# Setup .npmrc symlink
if [ -L "$USER_NPMRC" ]; then
    echo "✅ .npmrc symlink already exists"
elif [ -f "$USER_NPMRC" ]; then
    echo "🔄 Backing up existing .npmrc and creating symlink..."
    mv "$USER_NPMRC" "$USER_NPMRC.backup-$(date +%Y%m%d-%H%M%S)"
    ln -s "$DOTFILES_NPMRC" "$USER_NPMRC"
    echo "✅ .npmrc symlink created"
else
    ln -s "$DOTFILES_NPMRC" "$USER_NPMRC"
    echo "✅ .npmrc symlink created"
fi

# Verify npm configuration
if command -v npm >/dev/null; then
    NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
    if [ "$NPM_PREFIX" = "/home/zacbraddy/.local" ]; then
        echo "✅ npm prefix correctly configured to ~/.local"
    else
        echo "⚠️  npm prefix is set to: $NPM_PREFIX"
        echo "💡 Expected: /home/zacbraddy/.local"
    fi
else
    echo "⚠️  npm not found in PATH"
fi

echo "===== HMR COMPLETED ====="
echo "Run 'reload' or restart your shell to apply changes"
