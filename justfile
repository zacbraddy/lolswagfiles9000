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

# List all available secrets
secrets-list:
    @echo "Available secrets:"
    @sops -d secrets.yaml | yq e '. | keys | .[]' -

# Interactive wizard to manage secrets
secrets-wizard:
    #!/usr/bin/env bash
    set -euo pipefail

    # Function to get current secrets
    get_secrets() {
        sops -d secrets.yaml
    }

    # Function to update a secret
    update_secret() {
        local key=$1
        local value
        echo "Enter new value for $key (press Ctrl+D when done):"
        value=$(cat)
        sops -d secrets.yaml | yq e ".$key = \"$value\"" - | sops -e -i secrets.yaml
    }

    # Function to add a new secret
    add_secret() {
        local key
        local value
        echo "Enter name for new secret:"
        read -r key
        echo "Enter value (press Ctrl+D when done):"
        value=$(cat)
        sops -d secrets.yaml | yq e ".$key = \"$value\"" - | sops -e -i secrets.yaml
    }

    # Function to remove a secret
    remove_secret() {
        local key=$1
        sops -d secrets.yaml | yq e "del(.$key)" - | sops -e -i secrets.yaml
    }

    # Main menu
    while true; do
        echo "=== Secrets Management ==="
        echo "1) List all secrets"
        echo "2) Update existing secret"
        echo "3) Add new secret"
        echo "4) Remove secret"
        echo "5) Exit"
        echo "Choose an option (1-5):"
        read -r choice

        case $choice in
            1)
                echo "Current secrets:"
                get_secrets | yq e '. | keys | .[]' -
                ;;
            2)
                echo "Select secret to update:"
                get_secrets | yq e '. | keys | .[]' -
                read -r key
                update_secret "$key"
                ;;
            3)
                add_secret
                ;;
            4)
                echo "Select secret to remove:"
                get_secrets | yq e '. | keys | .[]' -
                read -r key
                remove_secret "$key"
                ;;
            5)
                exit 0
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done

# Decrypt secrets to view them
secrets-view:
    @sops -d secrets.yaml

# Encrypt secrets from plain file
secrets-encrypt:
    @sops -e -i secrets.yaml

# Decrypt secrets to plain file for editing
secrets-decrypt:
    @sops -d secrets.yaml > secrets.plain.yaml

# Edit secrets in your default editor
secrets-edit:
    @sops secrets.yaml

# Add a new secret (usage: just secrets-add name)
secrets-add name:
    @echo "Enter value for $name (press Ctrl+D when done):"
    @sops -d secrets.yaml | yq e ".$name = \"$$(cat)\"" - | sops -e -i secrets.yaml

# Remove a secret (usage: just secrets-remove name)
secrets-remove name:
    @sops -d secrets.yaml | yq e "del(.$name)" - | sops -e -i secrets.yaml

# Update a secret (usage: just secrets-update name)
secrets-update name:
    @echo "Enter new value for $name (press Ctrl+D when done):"
    @sops -d secrets.yaml | yq e ".$name = \"$$(cat)\"" - | sops -e -i secrets.yaml
