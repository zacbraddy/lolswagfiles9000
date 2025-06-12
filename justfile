install-cursor:
    bash ./scripts/install-cursor.sh

install-adobe-reader:
    bash ./scripts/install-adobe-reader.sh

home-manager-update:
	home-manager switch --flake .#zacbraddy -b backup

sync-cursor-settings:
	cp ~/.config/Cursor/User/settings.json nix/modules/cursor-settings.json
	if command -v home-manager >/dev/null && [ -f "$HOME/.config/home-manager/home.nix" ]; then \
		just home-manager-update; \
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

setup-ssh-github:
	if [ ! -f ~/.ssh/id_rsa ]; then \
	  ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y; \
	fi
	if ! grep -q github.com ~/.ssh/known_hosts 2>/dev/null; then \
	  ssh-keyscan github.com >> ~/.ssh/known_hosts; \
	fi
	if [ -z "$$GITHUB_TOKEN" ]; then \
	  read -rsp "Enter your GitHub Personal Access Token (with repo:admin:public_key scope): " GITHUB_TOKEN; echo; \
	fi
	PUBKEY=$$(cat ~/.ssh/id_rsa.pub)
	curl -H "Authorization: token $$GITHUB_TOKEN" \
	     -H "Accept: application/vnd.github.v3+json" \
	     --data "{\"title\":\"$$(hostname)\",\"key\":\"$$PUBKEY\"}" \
	     https://api.github.com/user/keys

install-jetbrains-toolbox:
	TOOLBOX_DIR="$HOME/jetbrains-toolbox"; \
	TOOLBOX_URL="https://download-cf.jetbrains.com/toolbox/jetbrains-toolbox-1.20.7940.tar.gz"; \
	mkdir -p "$TOOLBOX_DIR"; \
	cd "$TOOLBOX_DIR"; \
	if [ ! -f "jetbrains-toolbox" ]; then \
	  curl -L "$TOOLBOX_URL" -o toolbox.tar.gz; \
	  tar -xzf toolbox.tar.gz --strip-components=1; \
	  rm toolbox.tar.gz; \
	fi; \
	if [ -f "jetbrains-toolbox" ]; then \
	  chmod +x jetbrains-toolbox; \
	  echo "JetBrains Toolbox is ready in $TOOLBOX_DIR"; \
	  "$TOOLBOX_DIR/jetbrains-toolbox" & \
	else \
	  echo "JetBrains Toolbox install failed"; \
	  exit 1; \
	fi

# Secrets Management Recipes

# List all secrets
secrets-list:
    node scripts/secrets/list.js


# Decrypt secrets to view them
secrets-view:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Edit secrets in your default editor
secrets-edit:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Add a new secret (interactive CLI)
secrets-add:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @node scripts/secrets/add.js

# Remove a secret (interactive CLI)
secrets-remove:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @node scripts/secrets/remove.js

# Update a secret (interactive CLI)
secrets-update:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @node scripts/secrets/update.js

# Setup SOPS age key for secrets management
secrets-setup-key:
    @read -p "Enter your public key: " public_key; \
    read -p "Enter your private key: " private_key; \
    mkdir -p ~/.config/sops/age; \
    echo "# created: $$(date -Iseconds)" > ~/.config/sops/age/keys.txt; \
    echo "# public key: $$public_key" >> ~/.config/sops/age/keys.txt; \
    echo "$$private_key" >> ~/.config/sops/age/keys.txt; \
    echo "Keys updated at ~/.config/sops/age/keys.txt"; \
    echo "Your public key is: $$public_key"; \
    echo "Copying public key into .sops.yaml..."; \
    sed -i "s/age:.*/age: $$public_key/" nix/secrets/.sops.yaml; \
    echo "Public key copied into .sops.yaml."
