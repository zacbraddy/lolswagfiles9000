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

# Run Home Manager - let it handle all the symlinking automatically
echo "===== RUNNING HOME MANAGER ====="
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

home-manager switch \
    --flake "/home/zacbraddy/Projects/Personal/lolswagfiles9000#zacbraddy" \
    --show-trace \
    -b ".backup-$BACKUP_TIMESTAMP" \
    --extra-experimental-features "nix-command flakes" \
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

echo "===== HMR COMPLETED ====="
echo "Run 'reload' or restart your shell to apply changes"
