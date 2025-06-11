install-cursor:
    bash ./scripts/install-cursor.sh

install-adobe-reader:
    bash ./scripts/install-adobe-reader.sh

sync-cursor-settings:
	cp ~/.config/Cursor/User/settings.json nix/modules/cursor-settings.json
	if command -v home-manager >/dev/null && [ -f "$HOME/.config/home-manager/home.nix" ]; then \
		home-manager switch --flake .#zacbraddy; \
	else \
		echo "Home Manager is not set up. Please install and initialize it first."; \
	fi

diff-cursor-settings:
	diff -u nix/modules/cursor-settings.json ~/.config/Cursor/User/settings.json || true

bootstrap-home-manager:
	if ! command -v home-manager >/dev/null; then \
		nix-shell '<home-manager>' -A install; \
	else \
		echo "Home Manager already installed."; \
	fi
	mkdir -p $HOME/.config/home-manager
	echo "{ imports = [ \"$(pwd)/nix/modules/editors.nix\" ]; }" > $HOME/.config/home-manager/home.nix
	echo "Home Manager bootstrapped. You can now run 'just sync-cursor-settings'!"
