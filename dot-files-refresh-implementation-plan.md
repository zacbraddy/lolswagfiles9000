# Outstanding Tasks

- [x] Set up project directory structure for Nix/Home Manager modules
- [x] Create base Nix configuration (flake or default.nix)
- [ ] Bootstrap Home Manager integration
- [x] Implement shell.nix module (zsh, oh-my-zsh, terminal tools)
  - Base implementation complete and tested. Next: flesh out advanced zsh/oh-my-zsh customizations (prompt, plugins, aliases, etc.)
- [ ] Implement editors.nix module (Cursor, PyCharm, DbBeaver, vim configs)
- [ ] Implement languages.nix module (Python/Poetry, Node/pnpm, version managers)
- [ ] Implement devops.nix module (Terraform, cloud CLIs, GitHub CLI, Docker)
- [ ] Implement system.nix module (base system packages, fonts, utilities)
- [ ] Implement secrets.nix module (SSH keys, API tokens, encrypted configs)
- [ ] Design and implement CLI wizard (Justfile or similar)
- [ ] Integrate sops-nix for secrets management
- [ ] Test full rebuild and rollback process
- [ ] Review and migrate relevant configs/scripts from ansible-playbook and zsh directories

---

# Dotfiles Reimagination Project Plan

## Project Protocol

- **Goal**: Create a perfect development environment that allows machine rebuild at a moment's notice
- **Focus**: Reliability, automation, and easy ongoing updates
- **Approach**: Interview → Plan → Implement
- **Interview Style**: ONE question at a time, prefer yes/no or short answers
- **Artifact Usage**: Track progress, goals, and implementation plan across multiple chat sessions
- **Assistant Change Protocol**: The assistant will make changes directly without asking for permission. The user will request rollbacks if any changes are incorrect.
- **Documentation Check**: Always confirm Home Manager and Nix configuration changes against the official documentation before suggesting or applying them.

## Discovery Phase - Information Gathering

### Current Environment Assessment

- [x] Operating system(s) used: **PopOS (Ubuntu-based), has Nvidia GPU, open to other Linux distros**
- [x] Existing dotfiles status: **Has old repo (~5 years), out of date, many things broken, machine has evolved significantly**
- [x] Shell preferences: **zsh using oh-my-zsh**
- [x] Editor/IDE setup: **Migrating: WebStorm/PyCharm/DataGrip → Cursor/PyCharm (free)/DbBeaver. Vim keybinds preferred, uses vim plugins. Remove DoomEmacs from dotfiles**
- [x] Current development stack: **Full stack startup IC/solo dev: Python, Node, React, Terraform, GitHub Actions + supporting frameworks for complete web app build/deploy pipeline**
- [x] Package managers used: **System: apt/snap/flatpak/brew (wants consolidation), JS: npm/pnpm, Python: poetry. Open to management tools for simplification**
- [x] Automation tools experience: **Terraform, Ansible (current dotfiles use Ansible but it's flaky). Open to better alternatives including VM-based approach if workflow isn't impacted**

### Requirements Analysis

- [x] Machine rebuild frequency/scenarios: **Regular: ~annually, Ad-hoc: new workplace/client (data safety), system corruption recovery. Currently avoided due to broken dotfiles**
- [x] Cross-platform needs: **Primary: main dev machine. Future: Docker image deployable to EC2/cloud instances**
- [x] Team/sharing requirements: **Public repo sharing, need secure secrets management**
- [x] Backup/sync preferences: **Git-based dotfiles repo with symlinks (currently hit-and-miss). WANTS: Better automation for OS changes → dotfiles updates**
- [x] Update maintenance approach: **Priority: 1) Set-and-forget, 2) Monthly updates, 3) Daily tweaking (avoid as much as possible)**

### Technical Preferences

- [x] Configuration management approach: **Modular scripts organized by category (shell, editor, languages, etc.)**
- [x] Installation automation level: **CLI wizard (like Vorpal) with smart defaults for full environment, dependency tracking to prevent corrupted setups**
- [x] Customization vs simplicity balance: **Complete development environment - zero downtime after refresh (except script runtime)**
- [x] Version control strategy: **Manual commits (objective decision - avoids noise, maintains intentional change history)**

## Implementation Plan

### Technology Stack Decision

**Selected Approach**: **Nix + Home Manager + Just**

- **Nix/Home Manager**: Declarative, atomic rollbacks, handles all package management, maximum reliability
- **Just**: CLI wizard runner for modular installation
- **Rationale**: User prioritizes reliability over ease, comfortable with learning curve, single-machine use case

### Architecture Overview

**Unified Nix Configuration** - Everything managed through single declarative system:

- System packages & user environment via Home Manager
- Application configurations templated through Nix
- Shell setup (zsh + oh-my-zsh)
- Development tools (Cursor, PyCharm, DbBeaver)
- Language environments (Python/Poetry, Node/pnpm)
- Infrastructure tools (Terraform, cloud CLIs)
- All dotfiles and configs version controlled

### Module Structure (Function-Based)

- **shell.nix**: zsh, oh-my-zsh, terminal tools, prompt
- **editors.nix**: Cursor, PyCharm, DbBeaver, vim configs
- **languages.nix**: Python/Poetry, Node/pnpm, version managers
- **devops.nix**: Terraform, cloud CLIs, GitHub CLI, Docker
- **system.nix**: Base system packages, fonts, utilities
- **secrets.nix**: SSH keys, API tokens, encrypted configs

### CLI Wizard Design (Intelligent Granularity)

**Two-tier prompting system**:

1. **Module level**: "Setup shell environment? [Y/n]" (defaults to your standard config)
2. **Customization level**: "Customize shell setup? [y/N]" (only if they want to change defaults)

**Smart dependency handling**: Auto-enables required modules, shows what's being added
**Secrets management**: sops-nix for encrypted secrets in git, decrypted at build time

**Example flow**:

```
Setup shell environment? [Y/n] → Y (installs your standard zsh+oh-my-zsh config)
Setup editors? [Y/n] → Y
  Customize editor setup? [y/N] → y
    Install Cursor? [Y/n] → Y
    Install PyCharm? [Y/n] → N (they only want Cursor this time)
    Install DbBeaver? [Y/n] → Y
Setup languages? [Y/n] → Y
  → Auto-enabling shell (required for languages) ✓
  → Installing Python/Poetry, Node/pnpm with your defaults
```

**Result**: Fast default installs (6 Y's), full granularity when needed, smart dependency resolution

## Current Status

**Phase**: Implementation - In Progress 🚀
**Next**: Begin implementation with project structure and base Nix configuration

## Implementation Progress Notes

- 2024-06-10: Implementation phase started. Outstanding tasks checklist added. Ready to begin with repo structure and base Nix config.
- 2024-06-10: Existing Ansible playbooks and zsh configs identified. Will review and migrate relevant configs/scripts to new Nix modules as part of implementation.
- 2024-06-10: Nix/Home Manager directory structure and placeholder module files created. Ready to begin base Nix configuration.
- 2024-06-10: Modern flake.nix scaffolded with Home Manager integration and modular structure. Ready to bootstrap Home Manager and begin module implementation.
- 2024-06-10: Using nixos-unstable for latest features, but will revisit and switch to stable if all requirements are met with a stable channel. Prioritize stability if possible.
- 2024-06-10: Home Manager successfully bootstrapped using flake-based configuration. Legacy config warning is expected; always use --flake flag with home-manager commands. Assistant now makes changes without asking for permission, user will request rollbacks if needed.

## Ready for Implementation

All discovery and planning complete. Architecture designed for:

- Zero-downtime rebuilds via Nix/Home Manager
- Intelligent CLI wizard with smart defaults
- Modular function-based organization
- Encrypted secrets management
- Consolidated package management

## Next Steps for Continuation

**Current Question Pending**: ~~Do you prefer a more minimalist approach with just the essentials, or do you want a feature-rich setup with lots of tools and customizations?~~

**Discovery Complete!** Ready to move to Implementation Planning phase.

**Remaining Discovery Items**: ~~All completed~~

**Ready for Implementation Planning**: Once technical preferences are complete, we can move to creating the detailed implementation plan.

## Goals Identified

- Machine rebuild capability at moment's notice
- Reliable and repeatable setup process
- Easy ongoing updates and maintenance
- Developer experience optimization

## Current Status

**Phase**: Discovery - Information Gathering
**Next**: Continue interviewing to understand current setup and requirements

## Next Steps

- Focus next on advanced zsh/oh-my-zsh customization: prompt, plugins, aliases, and workflow enhancements.
- Start a new chat session from this context to continue with zsh improvements.
