# Outstanding Tasks

- [x] Set up project directory structure for Nix/Home Manager modules
- [x] Create base Nix configuration (flake or default.nix)
- [ ] Bootstrap Home Manager integration
- [x] Implement shell.nix module (zsh, oh-my-zsh, terminal tools)
  - Base implementation complete and tested. Next: flesh out advanced zsh/oh-my-zsh customizations (prompt, plugins, aliases, etc.)
  - Migrated all relevant zsh customizations (aliases, functions, completions, PATH, trash helpers, project jump, network info, reload, direnv, syntax highlighting, spicetify, etc.) to Home Manager.
  - Legacy .zshrc and related files are no longer needed; all config is now declarative and managed by Nix.
  - asdf is installed via home.packages, not as a Home Manager program.
  - Added robust trash management helpers and automatic cleanup on shell startup.
  - Added project jump, network info, and reload helpers for improved workflow.
  - Spicetify path is now managed by Nix.
- [x] Implement editors.nix module (Cursor, PyCharm, DbBeaver, vim configs)
  - **2025-06-01:** Added Home Manager activation script to automatically fix permissions for the Cursor config directory, preventing EACCES errors in Cursor/VSCode.
  - **2025-06-03:** Automated Cursor AppImage installation and MIME association using official API, robust to upstream changes. Script is idempotent and works on fresh systems. Justfile recipe provided for manual install as well.
- [x] Implement languages.nix module (Python/Poetry, Node/pnpm, version managers)
  - All global npm packages (e.g., c4builder) are now installed via Home Manager activation scripts if not available in Nixpkgs.
- [x] Implement devops.nix module (Terraform, cloud CLIs, GitHub CLI, Docker)
- [x] Implement system.nix module (base system packages, fonts, utilities)
- [ ] Implement secrets.nix module (SSH keys, API tokens, encrypted configs)
- [ ] Design and implement CLI wizard (Justfile or similar)
- [ ] Integrate sops-nix for secrets management
- [ ] Test full rebuild and rollback process
- [x] Review and migrate relevant configs/scripts from ansible-playbook directory (application installs migration complete)
  - **2025-06-03:** Adobe Reader, Cursor, and JetBrains Toolbox install tasks fully migrated to robust Justfile/bash automation. No longer managed by Ansible. .ideavimrc is now symlinked via Home Manager.
- [ ] Review and migrate remaining configs/scripts from ansible-playbook directory (in progress)
  - **2025-06-11:** JetBrains Toolbox install is now fully automated via Justfile (downloads, extracts, and launches the app). .ideavimrc is symlinked via Home Manager. All previous Ansible logic for these is obsolete and removed.
- [ ] Design and implement persistent file sync/backup solution (e.g., Google Drive, cloud sync) to automate keeping important files across system refreshes
- [ ] **Automation Principle:** Always prefer automation over manual steps. The Home Manager bootstrap and sync process for dotfiles/settings should be as pain-free and automated as possible.
- [ ] **Justfile Shell Variables:** Always use single $ for shell variable expansion in Justfile recipes (not $$). Double $$ causes bugs and has bitten us multiple times.
- [ ] **Always use flake-based Home Manager commands (e.g., 'home-manager switch --flake .#zacbraddy') for reproducibility and to ensure overlays like vscode-marketplace are available.**
- [ ] **Note:** Home Manager may return a non-zero exit code after activation (e.g., after removing or updating a profile), even if all activation steps complete successfully. This is a known issue and can be ignored if your settings and packages are correct. If you ask about this error in the future, the assistant should remind you of this note.

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

- 2025-06-01: Implementation phase started. Outstanding tasks checklist added. Ready to begin with repo structure and base Nix config.
- 2025-06-01: Existing Ansible playbooks and zsh configs identified. Will review and migrate relevant configs/scripts to new Nix modules as part of implementation.
- 2025-06-01: Nix/Home Manager directory structure and placeholder module files created. Ready to begin base Nix configuration.
- 2025-06-01: Modern flake.nix scaffolded with Home Manager integration and modular structure. Ready to bootstrap Home Manager and begin module implementation.
- 2025-06-01: Using nixos-unstable for latest features, but will revisit and switch to stable if all requirements are met with a stable channel. Prioritize stability if possible.
- 2025-06-01: Home Manager successfully bootstrapped using flake-based configuration. Legacy config warning is expected; always use --flake flag with home-manager commands. Assistant now makes changes without asking for permission, user will request rollbacks if needed.
- 2025-06-02: Migrated all zsh config (aliases, functions, completions, PATH, trash helpers, project jump, network info, reload, direnv, syntax highlighting, spicetify, etc.) to Home Manager. Legacy .zshrc and related files are now obsolete. asdf is installed via home.packages, not as a Home Manager program. Trash management and workflow helpers added. Spicetify path managed by Nix. **Zsh migration is now fully complete.**
- 2025-06-02: Next focus: Translate ansible-playbook scripts to Nix modules for full migration.
- 2025-06-02: Add a plan to explore/implement a persistent file sync/backup solution (e.g., Google Drive, cloud sync) to automate keeping important files across system refreshes.
- 2025-06-03: Application installation is now fully managed by Nix/Home Manager. All relevant CLI, GUI, devops, and language tools are declaratively specified. Global npm packages not in Nixpkgs are installed via activation scripts. Ansible application install scripts have been fully migrated to Nix modules.
- 2025-06-03: Next: Continue migration of remaining Ansible scripts (e.g., system tweaks, cloud tools, editor configs, etc.) to Nix modules.
- 2025-06-03: Cursor and Adobe Reader installation is now fully automated via Justfile/bash scripts. Cursor uses the official API for AppImage download and robust MIME association logic. Justfile is now robust and idempotent. JetBrains Toolbox is now automated via Justfile and launches after install. .ideavimrc is symlinked via Home Manager. Next: review and migrate/delete remaining Ansible tasks (system tweaks, cloud tools, editor configs, etc.) to Nix modules or remove if obsolete.

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


## Recent Progress

- **2025-06-01:** Implemented a Home Manager activation script in `editors.nix` to automatically fix permissions for the Cursor config directory. This ensures Cursor/VSCode can always write to its settings files, eliminating EACCES errors.
- **2025-06-02:** Migrated all zsh config (aliases, functions, completions, PATH, trash helpers, project jump, network info, reload, direnv, syntax highlighting, spicetify, etc.) to Home Manager. Legacy .zshrc and related files are now obsolete. asdf is installed via home.packages, not as a Home Manager program. Trash management and workflow helpers added. Spicetify path managed by Nix. **Zsh migration is now fully complete.**
- **2025-06-03:** Application installation is now fully managed by Nix/Home Manager. All relevant CLI, GUI, devops, and language tools are declaratively specified. Global npm packages not in Nixpkgs are installed via activation scripts. Ansible application install scripts have been fully migrated to Nix modules.
- **2025-06-03:** Cursor and Adobe Reader installation is now fully automated via Justfile/bash scripts. Cursor uses the official API for AppImage download and robust MIME association logic. Justfile is now robust and idempotent. JetBrains Toolbox is now automated via Justfile and launches after install. .ideavimrc is symlinked via Home Manager. Next: review and migrate/delete remaining Ansible tasks (system tweaks, cloud tools, editor configs, etc.) to Nix modules or remove if obsolete.

## Next Steps (as of 2025-06-03)

**The current focus is to complete the migration away from Ansible:**

- For each file in `ansible-playbook/main/tasks/`:
  1. Review and summarize what it does.
  2. Decide if it should be:
     - Migrated to a Nix module (preferred for declarative config)
     - Automated via a Justfile/bash script (if it requires imperative logic or root)
     - Deleted as obsolete (if no longer needed)
  3. Migrate or remove, and update this plan/checklist accordingly.

**Once all Ansible tasks are reviewed and handled, proceed to:**
- Implement secrets management (`secrets.nix` + sops-nix)
- Design and implement the CLI wizard
- Test full rebuild/rollback
- Plan/implement persistent file sync/backup
