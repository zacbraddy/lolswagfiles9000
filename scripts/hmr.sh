#!/usr/bin/env bash
set -e

# Set up directories
log_dir="$HOME/.aider/logs"
backup_dir="$HOME/.aider/backups"
config_dir="$HOME/.aider/config"

# Create all required directories if they don't exist
mkdir -p "$log_dir" "$backup_dir" "$config_dir" \
         "$HOME/.local/bin" \
         "$HOME/.local/state/home-manager/gcroots"

# Accept extra arguments for home-manager switch (e.g., -b backup)
HM_SWITCH_ARGS="$@"

# Unlink ~/.zshrc if it exists (file or symlink) to avoid Home Manager backup clobbering bug
if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  echo "Unlinking ~/.zshrc (removing file or symlink) to avoid Home Manager backup clobbering bug."
  rm "$HOME/.zshrc"
fi

# Remove any pre-Home Manager relinking of .zshrc

LATEST_ZSHENV=$(ls -t /nix/store/*-home-manager-files/.zshenv 2>/dev/null | head -n1)
if [ ! -L ~/.zshenv ] || [ "$(readlink ~/.zshenv)" != "$LATEST_ZSHENV" ]; then
  if [ -f ~/.zshenv ] && [ ! -L ~/.zshenv ]; then
    mv ~/.zshenv ~/.zshenv.backup
    echo 'Moved existing ~/.zshenv to ~/.zshenv.backup so Home Manager can manage it.'
  fi
  if [ -n "$LATEST_ZSHENV" ]; then
    ln -sf "$LATEST_ZSHENV" ~/.zshenv
    echo "Symlinked $LATEST_ZSHENV to ~/.zshenv (repair/check)"
  else
    echo "No generated .zshenv found in /nix/store (repair/check)."
  fi
fi

if [ ! -f ~/.config/sops/age/keys.txt ]; then
  echo '⚠️  Warning: Age key file not found at ~/.config/sops/age/keys.txt'
  echo "Please run 'just secrets-setup-key' to set up your encryption keys"
  exit 1
fi

if SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml 2>/dev/null | grep -q '^{}$'; then
  echo '⚠️  Warning: secrets.yaml is empty'
  echo "Please run 'just secrets-add' to add required secrets:"
  echo "  - aws_credentials"
  echo "  - github_token"
  echo "  - ssh_private_key"
  echo "  - ssh_public_key"
  echo "  - env_file"
  exit 1
fi

# Run Home Manager switch with consistent arguments
home-manager switch \
  --show-trace \
  --extra-experimental-features "nix-command flakes" \
  $HM_SWITCH_ARGS
HM_EXIT=$?

# Post-switch: re-symlink .zshrc and .zshenv if needed
LATEST_HM_FILES=$(find /nix/store -maxdepth 1 -name "*-home-manager-files" 2>/dev/null | sort | tail -n1)
if [ -n "$LATEST_HM_FILES" ]; then
  echo "Found Home Manager files at: $LATEST_HM_FILES"
  if [ -f "$LATEST_HM_FILES/.zshrc" ] && [ ! -e ~/.zshrc ]; then
    ln -sf "$LATEST_HM_FILES/.zshrc" ~/.zshrc
    echo "✅ Symlinked $LATEST_HM_FILES/.zshrc to ~/.zshrc (post-switch)"
  fi
  if [ -f "$LATEST_HM_FILES/.zshenv" ] && [ ! -L ~/.zshenv ]; then
    ln -sf "$LATEST_HM_FILES/.zshenv" ~/.zshenv
    echo "✅ Symlinked $LATEST_HM_FILES/.zshenv to ~/.zshenv (post-switch)"
  fi
else
  echo "⚠️  No Home Manager files directory found"
fi

echo "Done. Please run 'reload' or restart your shell to apply changes."
exit $HM_EXIT
