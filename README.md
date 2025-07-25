# :sunglasses: Lol Swag Yolo 9000 files :sunglasses:

## :crown: The ultimate modern development environment, powered by Nix! :crown:

This is a complete development environment that combines the power of Nix Flakes with Home Manager to create a reproducible, maintainable dotfiles setup. Built for developers who need reliable tooling across machine rebuilds and want maximum automation with minimal faffing about.

> **Note**: This setup has been completely modernised from the old Ansible approach to use Nix exclusively, making it more reliable and declarative than ever before.

## :rocket: Quick Start

### Brand New Machine (Pop!_OS/Ubuntu Installation)

If you're starting completely fresh or rebuilding an existing machine:

1. **Install Pop!_OS from scratch**:
   - **Download the correct Pop!_OS flavour**:
     - Visit [system76.com/pop/download](https://system76.com/pop/download/)
     - Choose **Pop!_OS 22.04 LTS with NVIDIA** if you have 16-series NVIDIA graphics or newer
     - Choose **Pop!_OS 22.04 LTS (Intel/AMD)** for Intel/AMD graphics or 10-series NVIDIA and older
     - Check your graphics card: `lspci | grep -i vga`
   - **Prepare for installation**:
     - Create a bootable USB drive using Rufus (Windows), Balena Etcher, or `dd` command
     - **Disable Secure Boot** in your BIOS/UEFI settings:
       - Restart and press F2/Delete during boot to enter BIOS
       - Navigate to Security → Secure Boot → Disabled
       - Save and exit (usually F10)
   - **Install Pop!_OS**:
     - Boot from USB and select "Clean Install" (this will wipe the entire drive)
     - Follow the installation wizard:
       - Choose your language and keyboard layout
       - Select "Erase disk and install Pop!_OS" for a fresh start
       - Create your user account (use the same username as your dotfiles if possible)
     - Complete the installation and reboot into your fresh Pop!_OS system

2. **Install essential tools**:
   ```bash
   sudo apt update && sudo apt install -y curl git httpie
   ```

3. **Clone this repository**:
   ```bash
   git clone https://github.com/zacbraddy/lolswagfiles9000.git ~/Projects/Personal/lolswagfiles9000
   cd ~/Projects/Personal/lolswagfiles9000
   ```

4. **Run the setup wizard** (this does everything for you):
   ```bash
   just setup-wizard
   ```

That's it! The wizard will guide you through the entire setup process including:
- Installing Nix and Home Manager
- Setting up secrets management
- Configuring Git and SSH
- Installing all applications
- Applying system configurations

### Existing Machine Migration

If you already have some tools installed:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/zacbraddy/lolswagfiles9000.git ~/Projects/Personal/lolswagfiles9000
   cd ~/Projects/Personal/lolswagfiles9000
   ```

2. **Install Nix** (if not already installed):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

3. **Run the setup wizard**:
   ```bash
   just setup-wizard
   ```

The wizard is smart enough to detect existing installations and will offer to skip or reconfigure as needed.

## :package: What's Included

### Core Development Tools

**Languages & Runtimes:**
- Node.js (with npm, yarn)
- Python 3 (with pip, pipx modules)
- Java (OpenJDK)
- Claude CLI (latest via npm)

**Editors & IDEs:**
- Cursor (with pre-configured settings and extensions)
- Obsidian (with 34+ plugins and custom configuration)
- Vim/Neovim
- Support for JetBrains Toolbox

**DevOps & Infrastructure:**
- Docker
- kubectl + kubectx/kubens
- AWS CLI + AWS Vault
- Google Cloud CLI
- Terraform
- rclone (for file sync)

**System Tools:**
- fzf (fuzzy finder)
- ripgrep + fd (modern grep/find replacements)
- zsh with Oh My Zsh
- Git with powerful aliases and configuration

### Applications (via Flatpak)

- **Communication**: Discord, Slack
- **Media**: VLC, OBS Studio, Spotify
- **Utilities**: Adobe Reader, Bitwarden, GIMP, Flameshot
- **Development**: Postman

### System Integrations

**Camera Fix Service** - Automated Logitech webcam configuration that persists across reboots

**Tuxedo Keyboard Support** - Custom keyboard configuration for Tuxedo laptops

**PulseAudio Configuration** - Optimised audio settings

## :gear: Key Features

### 1. **Automated Setup Wizard**
- One command setup from scratch
- Intelligent detection of existing tools
- Interactive prompts for configuration
- Comprehensive validation and troubleshooting

### 2. **Secrets Management**
- SOPS with age encryption for secure secrets storage
- Interactive CLI for managing secrets
- Secure API keys, tokens, and credentials
- Commands: `just secrets-add`, `just secrets-edit`, `just secrets-list`

### 3. **Obsidian Vault Management**
- Global commands available from any directory
- Smart plugin filtering (excludes runtime data, keeps configs)
- Multi-vault support with shared configuration
- Commands: `ob-create <vault>`, `ob-update`, `ob-refresh-dotfiles`

### 4. **File Backup System (Filestore)**
- Personal file backup to Google Drive
- Symlinked standard directories (Documents, Pictures, Downloads)
- Global commands: `bk-sync`, `bk-status`, `bk-pull`
- Perfect for machine rebuilds - backup before, restore after

### 5. **Claude Configuration Management**
- Symlinked configuration and memory files for seamless version control
- Claude configuration (`~/.claude/CLAUDE.md`) and memories (`~/.claude/memory/`) are symlinked to your dotfiles
- Edit your Claude config directly in the repo - changes are immediately live
- All your Claude memories and configuration are automatically version controlled

### 6. **Smart Home Manager Integration**
- Flake-based configuration
- Modular architecture for easy customisation
- Automatic activation scripts for system integration
- Cache management and troubleshooting tools

## :wrench: Available Commands

Run `just --list` to see all available commands. Key ones include:

**Setup & Management:**
- `just setup-wizard` - Complete setup from scratch
- `just hmr` - Reload Home Manager configuration
- `just validate-hm` - Validate configuration before applying

**Application Management:**
- `just install-cursor` - Install Cursor editor
- `just sync-cursor-settings` - Sync Cursor configuration
- `just install-jetbrains-toolbox` - Install JetBrains Toolbox

**Secrets Management:**
- `just secrets-add` - Add new secret
- `just secrets-edit` - Edit all secrets
- `just secrets-list` - List configured secrets

**Obsidian Management:**
- `just obsidian-vaults-list` - List managed vaults
- `just obsidian-sync` - Sync configuration to all vaults

**Claude Management:**
- Configuration and memories are automatically symlinked and version controlled
- Edit `claude/CLAUDE.md` directly in your dotfiles to modify Claude configuration

**System Maintenance:**
- `just clear-nix-cache` - Clean up Nix store
- `just setup-ssh-github` - Configure SSH for GitHub

## :file_folder: Repository Structure

```
├── nix/                    # Nix configuration modules
│   ├── home.nix           # Main Home Manager configuration
│   ├── flake.nix          # Nix Flake definition
│   ├── modules/           # Modular configurations
│   │   ├── shell.nix      # ZSH, aliases, Oh My Zsh
│   │   ├── editors.nix    # Cursor, Vim, extensions
│   │   ├── languages.nix  # Node, Python, Java
│   │   ├── devops.nix     # Docker, kubectl, cloud tools
│   │   ├── system.nix     # System packages and tools
│   │   ├── secrets.nix    # SOPS configuration
│   │   └── claude.nix     # Claude CLI configuration
│   └── secrets/           # Encrypted secrets storage
├── scripts/               # Automation scripts
│   ├── backup/           # Filestore backup system
│   ├── obsidian/         # Obsidian vault management
│   └── secrets/          # Secrets management CLI
├── obsidian/             # Obsidian configuration templates
├── claude/               # Claude configuration and memory (symlinked)
├── justfile              # Command definitions
└── README.md             # This file
```

## :zap: ZSH Configuration

### Custom Aliases
- **Git shortcuts**: `gs` (status), `ga` (add), `gc` (commit), `gp` (push)
- **System**: `reload` (restart zsh), `netinfo` (network status)
- **Safety**: `rm` mapped to `trash` (recoverable deletion)

### Oh My Zsh Plugins
- git, z, sudo, fzf, history-substring-search
- extract, colored-man-pages, alias-finder
- docker, node, vi-mode

### Global Commands
- **Obsidian**: `ob-create`, `ob-update`, `ob-refresh-dotfiles`
- **Backup**: `bk-sync`, `bk-status`, `bk-pull`

## :ambulance: Troubleshooting

### Common Issues

**Home Manager fails to activate:**
```bash
just clear-nix-cache
just hmr
```

**Cursor settings won't sync:**
```bash
# Make sure Cursor is closed first
just sync-cursor-settings
```

**Secrets not working:**
```bash
just secrets-setup-key
```

**Cache issues:**
```bash
just clear-nix-cache
just validate-hm
just hmr
```

### Reset Everything
If you need to start fresh:
```bash
just clear-nix-cache
rm -rf ~/.cache/nix
just setup-wizard
```

## :gear: Customisation

### Adding New Packages
Edit the relevant module in `nix/modules/`:
- `system.nix` - System utilities
- `languages.nix` - Programming languages
- `devops.nix` - DevOps tools
- `editors.nix` - Editors and IDEs

### Adding New Secrets
```bash
just secrets-add
# Follow the interactive prompts
```

### Creating New Obsidian Vaults
```bash
ob-create my-new-vault
# Automatically configured with all dotfiles settings
```

## :heart: Contributing

This is a personal dotfiles repository, but if you find bugs or have suggestions for improvements, feel free to open an issue or submit a pull request!

## :book: Additional Resources

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [SOPS Documentation](https://github.com/Mic92/sops-nix)
- [Just Command Runner](https://github.com/casey/just)

---

**Built with** :heart: **for developers who value automation, reproducibility, and not having to set up their environment from scratch every bloody time.**