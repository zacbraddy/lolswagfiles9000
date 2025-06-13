install-cursor:
	#!/usr/bin/env bash
	bash ./scripts/install-cursor.sh
	mkdir -p ~/.config/Cursor/User
	if [ -f ~/.config/Cursor/User/settings.json ]; then \
		echo "Found existing Cursor settings.json"; \
		echo "Settings are managed globally at ~/.config/Cursor/User/settings.json"; \
		echo "Use 'just sync-cursor-settings' to update settings."; \
	else \
		echo "Initial settings will be created on first Cursor launch."; \
	fi

install-adobe-reader:
	#!/usr/bin/env bash
	bash ./scripts/install-adobe-reader.sh

home-manager-update:
	#!/usr/bin/env bash
	home-manager switch --flake .#zacbraddy -b backup

sync-cursor-settings:
	#!/usr/bin/env bash
	mkdir -p ~/.config/Cursor/User
	if [ -f ~/.config/Cursor/User/settings.json ]; then \
		echo "Found existing Cursor settings.json"; \
		echo "Settings are managed globally at ~/.config/Cursor/User/settings.json"; \
		echo "Use your preferred editor to modify the settings file."; \
	else \
		echo "Initial settings will be created on first Cursor launch."; \
	fi

diff-cursor-settings:
	#!/usr/bin/env bash
	echo "Settings are managed globally at ~/.config/Cursor/User/settings.json"
	echo "Use your preferred editor to view and modify the settings file."

bootstrap-home-manager:
	#!/usr/bin/env bash
	if ! command -v home-manager >/dev/null; then \
		nix-shell '<home-manager>' -A install; \
	else \
		echo "Home Manager already installed."; \
	fi
	mkdir -p $HOME/.config/home-manager
	echo "{ imports = [ \"$(pwd)/nix/modules/editors.nix\" ]; }" > $HOME/.config/home-manager/home.nix
	echo "Home Manager bootstrapped. You can now run 'just sync-cursor-settings'!"

setup-ssh-github:
	#!/usr/bin/env bash
	if [ ! -f ~/.ssh/id_rsa ]; then \
	  ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y; \
	fi
	if ! grep -q github.com ~/.ssh/known_hosts 2>/dev/null; then \
	  ssh-keyscan github.com >> ~/.ssh/known_hosts; \
	fi
	if [ -z "$GITHUB_TOKEN" ]; then \
	  read -rsp "Enter your GitHub Personal Access Token (with repo:admin:public_key scope): " GITHUB_TOKEN; echo; \
	fi
	PUBKEY=$(cat ~/.ssh/id_rsa.pub)
	curl -H "Authorization: token $GITHUB_TOKEN" \
	     -H "Accept: application/vnd.github.v3+json" \
	     --data "{\"title\":\"$(hostname)\",\"key\":\"$PUBKEY\"}" \
	     https://api.github.com/user/keys

install-jetbrains-toolbox:
	#!/usr/bin/env bash
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
	#!/usr/bin/env bash
	node scripts/secrets/list.js


# Decrypt secrets to view them
secrets-view:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
		exit 1; \
	fi
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Edit secrets in your default editor
secrets-edit:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
		exit 1; \
	fi
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml

# Add a new secret (interactive CLI)
secrets-add:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
		exit 1; \
	fi
	node scripts/secrets/add.js

# Remove a secret (interactive CLI)
secrets-remove:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
		exit 1; \
	fi
	node scripts/secrets/remove.js

# Update a secret (interactive CLI)
secrets-update:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "Error: Age key file not found at ~/.config/sops/age/keys.txt. Please ensure it exists for decryption."; \
		exit 1; \
	fi
	node scripts/secrets/update.js

# Setup SOPS age key for secrets management
secrets-setup-key:
	#!/usr/bin/env bash
	read -p "Enter your public key: " public_key
	read -p "Enter your private key: " private_key
	mkdir -p ~/.config/sops/age
	echo "# created: $(date -Iseconds)" > ~/.config/sops/age/keys.txt
	echo "# public key: $public_key" >> ~/.config/sops/age/keys.txt
	echo "$private_key" >> ~/.config/sops/age/keys.txt
	echo "Keys updated at ~/.config/sops/age/keys.txt"
	echo "Your public key is: $public_key"
	echo "Copying public key into .sops.yaml..."
	sed -i "s/age:.*/age: $public_key/" nix/secrets/.sops.yaml
	echo "Public key copied into .sops.yaml."

# Home Manager Reload with secret checks
hmr:
	#!/usr/bin/env bash
	if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "⚠️  Warning: Age key file not found at ~/.config/sops/age/keys.txt"; \
		echo "Please run 'just secrets-setup-key' to set up your encryption keys"; \
		exit 1; \
	fi; \
	if SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml 2>/dev/null | grep -q '^{}$'; then \
		echo "⚠️  Warning: secrets.yaml is empty"; \
		echo "Please run 'just secrets-add' to add required secrets:"; \
		echo "  - aws_credentials"; \
		echo "  - github_token"; \
		echo "  - ssh_private_key"; \
		echo "  - ssh_public_key"; \
		echo "  - env_file"; \
		exit 1; \
	fi; \
	home-manager switch --flake .#zacbraddy -b backup

hmr-with-exit-check:
	#!/usr/bin/env bash
	HM_EXIT=$(just hmr > /dev/null 2>&1; echo $?)
	if [ "$HM_EXIT" -eq 0 ]; then
		echo "✅ Home Manager configuration applied successfully"
	elif [ "$HM_EXIT" -eq 1 ]; then
		echo "⚠️  Home Manager configuration completed with warnings"
		echo "    This is normal and your configuration should still be active"
	else
		echo "❌ Home Manager configuration failed with error code $HM_EXIT"
		echo "    Please check the error messages above and try again"
		exit $HM_EXIT
	fi

setup-wizard:
	#!/usr/bin/env bash
	echo "🚀 Starting Dotfiles Setup Wizard"
	echo "--------------------------------"
	echo "Checking system requirements..."
	if ! command -v nix >/dev/null; then
		echo "❌ Nix is not installed. Please install Nix first."
		exit 1
	fi
	if ! command -v home-manager >/dev/null; then
		echo "⚠️  Home Manager not found. Installing..."
		just bootstrap-home-manager
	else
		echo "✅ Home Manager already installed."
	fi
	echo "✅ System requirements met"
	echo
	echo "🔐 Setting up secrets management..."
	if [ ! -f ~/.config/sops/age/keys.txt ]; then
		echo "⚠️  Age key not found. Please set up your encryption keys:"
		just secrets-setup-key
	else
		echo "✅ Age key already exists."
	fi
	echo "✅ Secrets management ready"
	echo
	echo "📦 Checking required secrets..."
	if SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml 2>/dev/null | grep -q '^{}$'; then
		echo "⚠️  No secrets found. Let's set them up:"
		just secrets-add
	else
		echo "✅ Secrets already configured."
	fi
	echo "✅ Secrets configured"
	echo
	echo "🔄 Setting up Git configuration..."
	if [ -f ~/.gitconfig ]; then
		echo "Git config already exists. Do you want to reconfigure? [y/N]"
		read -r reconfig_git
		if [[ $reconfig_git =~ ^[Yy]$ ]]; then
			read -p "Enter your Git email: " git_email
			read -p "Enter your Git name: " git_name
			git config --global user.email "$git_email"
			git config --global user.name "$git_name"
			echo "✅ Git reconfigured."
		else
			echo "Keeping existing Git config."
		fi
	else
		read -p "Enter your Git email: " git_email
		read -p "Enter your Git name: " git_name
		git config --global user.email "$git_email"
		git config --global user.name "$git_name"
		echo "✅ Git configured."
	fi
	echo
	echo "🔑 Setting up SSH and GitHub..."
	if [ -f ~/.ssh/id_rsa ]; then
		echo "SSH key already exists. Do you want to regenerate? [y/N]"
		read -r regen_ssh
		if [[ $regen_ssh =~ ^[Yy]$ ]]; then
			ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y
			echo "✅ SSH key regenerated."
		else
			echo "Keeping existing SSH key."
		fi
	else
		echo "Generating SSH key..."
		ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y
		echo "✅ SSH key generated."
	fi
	if ! grep -q github.com ~/.ssh/known_hosts 2>/dev/null; then
		ssh-keyscan github.com >> ~/.ssh/known_hosts
		echo "✅ GitHub known hosts updated."
	else
		echo "✅ GitHub known hosts already configured."
	fi
	echo "✅ SSH configured"
	echo
	echo "📦 Installing core applications..."
	echo "Installing Cursor..."
	if command -v cursor >/dev/null; then
		echo "Cursor already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_cursor
		if [[ $reinstall_cursor =~ ^[Yy]$ ]]; then
			just install-cursor
		else
			echo "Keeping existing Cursor installation."
		fi
	else
		just install-cursor
	fi
	echo "Installing Adobe Reader..."
	if command -v acroread >/dev/null; then
		echo "Adobe Reader already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_adobe
		if [[ $reinstall_adobe =~ ^[Yy]$ ]]; then
			just install-adobe-reader
		else
			echo "Keeping existing Adobe Reader installation."
		fi
	else
		just install-adobe-reader
	fi
	echo "Installing JetBrains Toolbox..."
	if [ -f "$HOME/jetbrains-toolbox/jetbrains-toolbox" ]; then
		echo "JetBrains Toolbox already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_toolbox
		if [[ $reinstall_toolbox =~ ^[Yy]$ ]]; then
			bash ./scripts/install-jetbrains-toolbox.sh
		else
			echo "Keeping existing JetBrains Toolbox installation."
		fi
	else
		bash ./scripts/install-jetbrains-toolbox.sh
	fi
	echo "✅ Core applications installed"
	echo
	echo "🔄 Applying Home Manager configuration..."
	just hmr-with-exit-check
	echo
	echo "🔄 Syncing Cursor settings..."
	just sync-cursor-settings
	echo
	echo "🔧 Setting up system tweaks..."
	if [ -f ./scripts/install-camera-fix-service.sh ]; then
		./scripts/install-camera-fix-service.sh
	fi
	echo "✅ System tweaks applied"
	echo
	echo "🔍 Verifying installation..."
	echo "Checking core tools..."
	for cmd in git curl wget vim; do
		if ! command -v $cmd >/dev/null; then
			echo "❌ $cmd not found"
		else
			echo "✅ $cmd installed"
		fi
	done
	echo "Checking development tools..."
	for cmd in node npm python3 pip3; do
		if ! command -v $cmd >/dev/null; then
			echo "❌ $cmd not found"
		else
			echo "✅ $cmd installed"
		fi
	done
	echo
	echo "✨ Setup complete! Your development environment is ready."
	echo "Next steps:"
	echo "  1. Review any warnings from the setup process above"
	echo "  2. Install Cursor extensions:"
	echo "     - Open Cursor"
	echo "     - Go to Extensions tab"
	echo "     - Install all recommended extensions"
	echo "  3. Configure JetBrains Toolbox:"
	echo "     - Launch JetBrains Toolbox"
	echo "     - Install your preferred IDEs"
	echo "  4. Check 'just --list' for available commands"
	echo
	echo "🔧 Troubleshooting:"
	echo "  - If Home Manager fails, run 'just hmr' to retry"
	echo "  - For Cursor issues, run 'just sync-cursor-settings'"
	echo "  - For secrets issues, run 'just secrets-setup-key'"
	echo "  - For system tweaks, check ./scripts/ directory"
