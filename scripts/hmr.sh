#!/usr/bin/env bash
set -e

# Accept extra arguments for home-manager switch (e.g., -b backup)
HM_SWITCH_ARGS="$@"

LATEST_ZSHRC=$(ls -t /nix/store/*-hm_.zshrc 2>/dev/null | head -n1)
if [ ! -L ~/.zshrc ] || [ "$(readlink ~/.zshrc)" != "$LATEST_ZSHRC" ]; then
  if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.backup
    echo 'Moved existing ~/.zshrc to ~/.zshrc.backup so Home Manager can manage it.'
  fi
  if [ -n "$LATEST_ZSHRC" ]; then
    ln -sf "$LATEST_ZSHRC" ~/.zshrc
    echo "Symlinked $LATEST_ZSHRC to ~/.zshrc (repair/check)"
  else
    echo "No generated .zshrc found in /nix/store (repair/check)."
  fi
fi

LATEST_ZSHENV=$(ls -t /nix/store/*-home-manager-files/.zshenv 2>/dev/null | head -n1)
if [ ! -L ~/.zshenv ] || [ "$(readlink ~/.zshenv)" != "$LATEST_ZSHENV" ]; then
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

set +e
home-manager switch --flake /home/zacbraddy/Projects/Personal/lolswagfiles9000#zacbraddy $HM_SWITCH_ARGS
HM_EXIT=$?
set -e

LATEST_ZSHRC=$(ls -t /nix/store/*-hm_.zshrc 2>/dev/null | head -n1)
if [ -n "$LATEST_ZSHRC" ]; then
  ln -sf "$LATEST_ZSHRC" ~/.zshrc
  echo "Symlinked $LATEST_ZSHRC to ~/.zshrc (post-switch)"
else
  echo "No generated .zshrc found in /nix/store (post-switch)."
fi

LATEST_ZSHENV=$(ls -t /nix/store/*-home-manager-files/.zshenv 2>/dev/null | head -n1)
if [ -n "$LATEST_ZSHENV" ]; then
  ln -sf "$LATEST_ZSHENV" ~/.zshenv
  echo "Symlinked $LATEST_ZSHENV to ~/.zshenv (post-switch)"
else
  echo "No generated .zshenv found in /nix/store (post-switch)."
fi

echo "Done. Please run 'reload' or restart your shell to apply changes."
exit $HM_EXIT
