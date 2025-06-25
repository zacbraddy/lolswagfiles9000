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

# Verify and create symlinks
echo "===== VERIFYING SYMLINKS ====="
# Get the most recently created home-manager-files directory
HM_FILES_PATH=$(find /nix/store -name "*home-manager-files*" -type d -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [ -n "$HM_FILES_PATH" ]; then
    # Create .zshrc symlink
    if [ -f "$HM_FILES_PATH/.zshrc" ]; then
        ln -sf "$HM_FILES_PATH/.zshrc" "$HOME/.zshrc"
        echo "✅ Created .zshrc symlink to: $HM_FILES_PATH/.zshrc"
    else
        echo "❌ Could not find generated .zshrc in home-manager files"
        exit 1
    fi

    # Create .p10k.zsh symlink
    if [ -f "$HM_FILES_PATH/.p10k.zsh" ]; then
        ln -sf "$HM_FILES_PATH/.p10k.zsh" "$HOME/.p10k.zsh"
        echo "✅ Created .p10k.zsh symlink to: $HM_FILES_PATH/.p10k.zsh"
    else
        echo "⚠️  No .p10k.zsh found in home-manager files (this may be normal)"
    fi
else
    echo "❌ Could not find home-manager files in Nix store"
    exit 1
fi

echo "===== HMR COMPLETED ====="
echo "Run 'reload' or restart your shell to apply changes"
