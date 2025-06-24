install-cursor:
	#!/usr/bin/env bash
	# Install Cursor AppImage and set up desktop integration
	bash ./scripts/install-cursor.sh

install-adobe-reader:
	#!/usr/bin/env bash
	bash ./scripts/install-adobe-reader.sh

home-manager-update:
	#!/usr/bin/env bash
	home-manager switch --flake .#zacbraddy -b backup

sync-cursor-settings:
	#!/usr/bin/env bash
	mkdir -p ~/.config/Cursor/User
	# Check if Cursor is running
	if pgrep -x "Cursor" > /dev/null; then
		echo "⚠️  Cursor is currently running. Please close Cursor before syncing settings."
		echo "This is required to prevent permission issues with the configuration files."
		exit 1
	fi
	# Function to handle file sync
	sync_file() {
		local file=$1
		local source_file=$2
		if [ -f ~/.config/Cursor/User/$file ]; then \
			echo "Found existing Cursor $file"; \
			echo "Do you want to overwrite it? [y/N]"; \
			read -r overwrite; \
			if [[ $overwrite =~ ^[Yy]$ ]]; then \
				echo "Overwriting $file..."; \
				if cp $source_file ~/.config/Cursor/User/$file; then \
					echo "✅ $file updated successfully."; \
					return 0; \
				else \
					echo "❌ Failed to update $file."; \
					echo "   Please ensure Cursor is closed and try again."; \
					return 1; \
				fi; \
			else \
				echo "Keeping existing $file"; \
				echo "Use your preferred editor to modify the file."; \
				return 0; \
			fi; \
		else \
			echo "Creating new $file..."; \
			if cp $source_file ~/.config/Cursor/User/$file; then \
				echo "✅ $file created successfully."; \
				return 0; \
			else \
				echo "❌ Failed to create $file."; \
				echo "   Please ensure Cursor is closed and try again."; \
				return 1; \
			fi; \
		fi
	}
	# Sync settings.json
	sync_file "settings.json" ".config/Cursor/User/settings.json"
	# Sync extensions.json
	sync_file "extensions.json" ".config/Cursor/User/extensions.json"

diff-cursor-settings:
	#!/usr/bin/env bash
	if [ -f ~/.config/Cursor/User/settings.json ]; then \
		echo "Diffing current settings with dotfiles settings:"; \
		echo "----------------------------------------"; \
		diff -u ~/.config/Cursor/User/settings.json .config/Cursor/User/settings.json || true; \
	else \
		echo "No existing settings found at ~/.config/Cursor/User/settings.json"; \
		echo "Use 'just sync-cursor-settings' to create initial settings."; \
	fi

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
	bash ~/Projects/Personal/lolswagfiles9000/scripts/hmr.sh -b hmbackup

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
	echo "🔍 Checking system requirements..."
	if ! command -v nix >/dev/null; then
		echo "⚠️  Nix not found. Installing Nix..."
		sh <(curl -L https://nixos.org/nix/install) --daemon
		# Source nix environment for current shell
		. "$HOME/.nix-profile/etc/profile.d/nix.sh"
	else
		echo "✅ Nix already installed."
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
		echo "📝 Git config already exists. Do you want to reconfigure? [y/N]"
		read -r reconfig_git
		if [[ $reconfig_git =~ ^[Yy]$ ]]; then
			read -p "Enter your Git email: " git_email
			read -p "Enter your Git name: " git_name
			git config --global user.email "$git_email"
			git config --global user.name "$git_name"
			echo "✅ Git reconfigured."
		else
			echo "ℹ️  Keeping existing Git config."
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
		echo "🔐 SSH key already exists. Do you want to regenerate? [y/N]"
		read -r regen_ssh
		if [[ $regen_ssh =~ ^[Yy]$ ]]; then
			ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y
			echo "✅ SSH key regenerated."
		else
			echo "ℹ️  Keeping existing SSH key."
		fi
	else
		echo "🔐 Generating SSH key..."
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
	echo "💻 Installing Cursor..."
	if command -v cursor >/dev/null; then
		echo "ℹ️  Cursor already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_cursor
		if [[ $reinstall_cursor =~ ^[Yy]$ ]]; then
			just install-cursor
		else
			echo "ℹ️  Keeping existing Cursor installation."
		fi
	else
		just install-cursor
	fi
	echo "⚙️  Syncing Cursor settings..."
	if ! just sync-cursor-settings; then
		echo "❌ Failed to sync Cursor settings."
		exit 1
	fi
	echo "⚙️  Syncing Obsidian settings..."
	if ! just sync-obsidian-settings; then
		echo "❌ Failed to sync Obsidian settings."
		exit 1
	fi
	echo "📄 Installing Adobe Reader..."
	if command -v acroread >/dev/null; then
		echo "ℹ️  Adobe Reader already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_adobe
		if [[ $reinstall_adobe =~ ^[Yy]$ ]]; then
			just install-adobe-reader
		else
			echo "ℹ️  Keeping existing Adobe Reader installation."
		fi
	else
		just install-adobe-reader
	fi
	echo "🛠️  Installing JetBrains Toolbox..."
	if [ -f "$HOME/jetbrains-toolbox/jetbrains-toolbox" ]; then
		echo "ℹ️  JetBrains Toolbox already installed. Do you want to reinstall? [y/N]"
		read -r reinstall_toolbox
		if [[ $reinstall_toolbox =~ ^[Yy]$ ]]; then
			bash ./scripts/install-jetbrains-toolbox.sh
		else
			echo "ℹ️  Keeping existing JetBrains Toolbox installation."
		fi
	else
		bash ./scripts/install-jetbrains-toolbox.sh
	fi
	echo "✅ Core applications installed"
	echo
	echo "🔄 Applying Home Manager configuration..."
	just hmr-with-exit-check
	echo
	echo "🔧 Setting up system tweaks..."
	if [ -f ./scripts/install-camera-fix-service.sh ]; then
		./scripts/install-camera-fix-service.sh
	fi
	echo "✅ System tweaks applied"
	echo
	echo "🔍 Verifying installation..."
	echo "📦 Checking core tools..."
	for cmd in git curl wget vim nix home-manager; do
		if ! command -v $cmd >/dev/null; then
			echo "❌ $cmd not found"
		else
			echo "✅ $cmd installed"
		fi
	done
	echo "🛠️  Checking development tools..."
	for cmd in node npm python3 pip3; do
		if ! command -v $cmd >/dev/null; then
			echo "❌ $cmd not found"
		else
			echo "✅ $cmd installed"
		fi
	done
	echo "💻 Checking IDE installations..."
	for ide in cursor acroread obsidian; do
		if ! command -v $ide >/dev/null; then
			echo "❌ $ide not found"
		else
			echo "✅ $ide installed"
		fi
	done
	if [ ! -f "$HOME/jetbrains-toolbox/jetbrains-toolbox" ]; then
		echo "❌ JetBrains Toolbox not found"
	else
		echo "✅ JetBrains Toolbox installed"
	fi
	echo
	echo "✨ Setup complete! Your development environment is ready."
	echo "📋 Next steps:"
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

sync-obsidian-settings:
	#!/usr/bin/env bash
	mkdir -p ~/.config/obsidian
	# Check if Obsidian is running
	if pgrep -x "Obsidian" > /dev/null; then
		echo "⚠️  Obsidian is currently running. Please close Obsidian before syncing settings."
		echo "This is required to prevent permission issues with the configuration files."
		exit 1
	fi
	# Function to handle file sync
	sync_file() {
		local file=$1
		local source_file=$2
		if [ -f ~/.config/obsidian/$file ]; then \
			echo "Found existing Obsidian $file"; \
			echo "Do you want to overwrite it? [y/N]"; \
			read -r overwrite; \
			if [[ $overwrite =~ ^[Yy]$ ]]; then \
				echo "Overwriting $file..."; \
				if cp $source_file ~/.config/obsidian/$file; then \
					echo "✅ $file updated successfully."; \
					return 0; \
				else \
					echo "❌ Failed to update $file."; \
					echo "   Please ensure Obsidian is closed and try again."; \
					return 1; \
				fi; \
			else \
				echo "Keeping existing $file"; \
				echo "Use your preferred editor to modify the file."; \
				return 0; \
			fi; \
		else \
			echo "Creating new $file..."; \
			if cp $source_file ~/.config/obsidian/$file; then \
				echo "✅ $file created successfully."; \
				return 0; \
			else \
				echo "❌ Failed to create $file."; \
				echo "   Please ensure Obsidian is closed and try again."; \
				return 1; \
			fi; \
		fi
	}
	# Sync settings files
	sync_file "appearance.json" "obsidian/appearance.json"
	sync_file "community-plugins.json" "obsidian/community-plugins.json"
	sync_file "core-plugins.json" "obsidian/core-plugins.json"
	sync_file "workspace.json" "obsidian/workspace.json"

# Obsidian Vault Management Recipes

# List all configured vaults
obsidian-vaults-list:
	#!/usr/bin/env bash
	node scripts/obsidian/manage-vaults.js list

# Add a new vault
obsidian-vaults-add:
	#!/usr/bin/env bash
	node scripts/obsidian/manage-vaults.js add

# Remove a vault
obsidian-vaults-remove:
	#!/usr/bin/env bash
	node scripts/obsidian/manage-vaults.js remove

# Edit an existing vault
obsidian-vaults-edit:
	#!/usr/bin/env bash
	node scripts/obsidian/manage-vaults.js edit

# Sync Obsidian configuration to all vaults
obsidian-sync:
	#!/usr/bin/env bash
	node scripts/obsidian/sync.js
