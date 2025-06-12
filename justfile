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
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @echo "Available secrets:"
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml | yq '. | keys | .[]'

# Interactive wizard to manage secrets
secrets-wizard:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @echo "Secrets Management Wizard"
    @echo "1. List secrets"
    @echo "2. Update secret"
    @echo "3. Add secret"
    @echo "4. Remove secret"
    @read -p "Choose an option: " option; \
    case $$option in \
        1) just secrets-list ;; \
        2) read -p "Enter secret name: " name; just secrets-update $$name ;; \
        3) read -p "Enter secret name: " name; just secrets-add $$name ;; \
        4) read -p "Enter secret name: " name; just secrets-remove $$name ;; \
        *) echo "Invalid option" ;; \
    esac

# Decrypt secrets to view them
secrets-view:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Encrypt secrets from plain file
secrets-encrypt:
    @sops -e --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml > nix/secrets/secrets.yaml.encrypted && mv nix/secrets/secrets.yaml.encrypted nix/secrets/secrets.yaml

# Decrypt secrets to plain file for editing
secrets-decrypt:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml > nix/secrets/secrets.plain.yaml

# Edit secrets in your default editor
secrets-edit:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Add a new secret (usage: just secrets-add name)
secrets-add name:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @read -p "Enter value for $$name: " value; \
    SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml | yq ".$$name = \"$$value\"" | sops -e --config nix/secrets/.sops.yaml > nix/secrets/secrets.yaml.encrypted && mv nix/secrets/secrets.yaml.encrypted nix/secrets/secrets.yaml

# Remove a secret (usage: just secrets-remove name)
secrets-remove:
    node scripts/secrets-cli.js

# Update a secret (usage: just secrets-update name)
secrets-update name:
    @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
        echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
        exit 1; \
    fi
    @read -p "Enter new value for $$name: " value; \
    SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml | yq ".$$name = \"$$value\"" | sops -e --config nix/secrets/.sops.yaml > nix/secrets/secrets.yaml.encrypted && mv nix/secrets/secrets.yaml.encrypted nix/secrets/secrets.yaml

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

# Test recipe to verify argument passing
test-arg name:
    echo "test name=$name"
