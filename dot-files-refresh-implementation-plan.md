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
- [x] Implement secrets.nix module (SSH keys, API tokens, encrypted configs)
- [ ] Design and implement CLI wizard (Justfile or similar)
- [x] Integrate sops-nix for secrets management
- [ ] Test full rebuild and rollback process
- [x] Review and migrate relevant configs/scripts from ansible-playbook directory (application installs migration complete)
  - **2025-06-03:** Adobe Reader, Cursor, and JetBrains Toolbox install tasks fully migrated to robust Justfile/bash automation. No longer managed by Ansible. .ideavimrc is now symlinked via Home Manager.
- [x] Review and migrate remaining configs/scripts from ansible-playbook directory (in progress)
  - **2025-06-12:** All remaining Ansible tasks and playbooks in ansible-playbook/main have been reviewed and deleted as obsolete. Migration from Ansible is now fully complete. All package management, configuration, and automation is handled by Nix/Home Manager and Justfile/bash scripts.
- [ ] Design and implement persistent file sync/backup solution (e.g., Google Drive, cloud sync) to automate keeping important files across system refreshes
- [ ] **Automation Principle:** Always prefer automation over manual steps. The Home Manager bootstrap and sync process for dotfiles/settings should be as pain-free and automated as possible.
- [ ] **Justfile Shell Variables:** Always use single $ for shell variable expansion in Justfile recipes (not $$). Double $$ causes bugs and has bitten us multiple times.
- [ ] **Always use flake-based Home Manager commands (e.g., 'home-manager switch --flake .#zacbraddy') for reproducibility and to ensure overlays like vscode-marketplace are available.**
- [ ] **Note:** Home Manager may return a non-zero exit code after activation (e.g., after removing or updating a profile), even if all activation steps complete successfully. This is a known issue and can be ignored if your settings and packages are correct. If you ask about this error in the future, the assistant should remind you of this note.
- [ ] **Justfile Indentation Troubleshooting:** When writing multi-line script blocks in Justfiles, always use exactly four spaces (no tabs) for indentation under the 'script:' keyword. Extra spaces, tabs, or inconsistent indentation will cause 'extra leading whitespace' errors. If you encounter this, check for invisible characters and ensure all lines are indented with four spaces only. See the 'Justfile Shell Variables' note for related pitfalls.

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

## Next Steps (as of 2025-06-12)

With the Ansible migration complete, the next focus areas are:
- ~~Implement secrets management (secrets.nix + sops-nix)~~ ✅
- Design and implement the CLI wizard (Justfile or similar)
- Test full rebuild and rollback process
- Plan and implement persistent file sync/backup solution

# Implementation Plan

## Secrets Management Strategy

### Current Implementation
- sops-nix integration for encrypted secrets management
- CRUD operations via Node.js scripts for managing `secrets.yaml`
- Required secrets defined in `secrets.nix`
- Basic validation in `hmr` command

### Planned Changes
1. **Simplify Secrets Management**
   - Remove automatic Nix configuration updates from secrets CRUD scripts
   - Keep CRUD operations focused solely on managing encrypted values in `secrets.yaml`
   - Document manual process for updating `secrets.nix` when new secrets are needed

2. **Documentation Requirements**
   - Document process for adding new secrets to the system
   - Include step-by-step guide for updating `secrets.nix`
   - Provide examples of common secret configurations

## CLI Wizard Implementation Plan

### Core Features
1. **Initial Setup**
   - System requirements check
   - Home Manager installation verification
   - Directory structure creation

2. **Secrets Management**
   - Read required secrets from `secrets.nix`
   - Check for missing secrets in `secrets.yaml`
   - Guide user through setting up each required secret
   - Validate secret setup completion

3. **Module Configuration**
   - Interactive module selection
   - Module-specific configuration options
   - Dependency validation

4. **Post-Setup**
   - System validation
   - Next steps guidance
   - Troubleshooting information

### Implementation Details
- Use Node.js with inquirer for interactive prompts
- Leverage existing just commands
- Implement progress tracking
- Add validation at each step
- Provide clear error messages and recovery steps

## Lessons Learned: Creating Justfiles Correctly

1. **Multi-line Recipes:**
   - Each line in a multi-line recipe must end with a backslash (`\`), except the last line.
   - This ensures the shell treats the recipe as a single logical line.
   - When writing multi-line script blocks in Justfiles, always use exactly four spaces (no tabs) for indentation under the 'script:' keyword.
   - Extra spaces, tabs, or inconsistent indentation will cause 'extra leading whitespace' errors.
   - Check for invisible characters and ensure all lines are indented with four spaces only.

2. **Argument Passing:**
   - Named arguments in Just are passed as environment variables to the recipe.
   - Use `$name` (not `$1` or `name="$1"`) to reference named arguments.
   - Always use single `$` for shell variable expansion in Justfile recipes (not `$$`).
   - Double `$$` causes bugs and has bitten us multiple times.
   - If the shell is running with `set -u` (nounset), unset variables will cause errors. Use `${name:-}` to provide a default value if needed.

3. **Interactive CLI with Node.js:**
   - For complex, interactive workflows (e.g., multi-select, confirmation prompts), consider using Node.js with libraries like `inquirer`.
   - This approach provides a more pleasant user experience and robust error handling.
   - Ensure the Node.js script is compatible with ES modules (use `import` instead of `require`).

4. **Error Handling:**
   - Always check for errors in command execution and provide clear error messages.
   - Use `try-catch` blocks in Node.js scripts to handle errors gracefully.
   - Test recipes thoroughly, especially when dealing with file operations or external commands.
   - Use `set -x` for debugging to see the exact commands being executed.

## Next Steps

- Debug and rewrite other secrets-related Justfile scripts to ensure they work as expected.
- Ensure consistency in argument handling, error messages, and interactive features across all secrets management scripts.

## Extension Installation in Cursor

- Note: Extension installation is managed via the recommended extensions feature. Open Cursor, go to the Extensions tab, and install all extensions listed under 'Recommended'. This process should be documented in the user setup guide.

## Implementation Progress Update (as of [today's date])

### Cursor Editor Extension Management
- **Automated VSIX Download:**
  - A Justfile task (`download-vsix`) automates downloading the latest VSIX files for all extensions listed in `extensions.json`.
  - The script uses a user agent to avoid corrupt downloads and stores VSIX files in a git-ignored `extensions-vsix/` directory.
- **Manual Installation Required:**
  - Due to Cursor v1.0 limitations, extensions must be installed manually by drag-and-dropping the VSIX files into the Extensions tab.
  - This step is required for new setups or when extensions are missing.
  - Copying or symlinking extension folders does **not** work in Cursor.
- **Documentation Updated:**
  - All manual steps are clearly documented in the README and implementation plan.

### Secrets Management
- **sops-nix and age keys** are set up for robust secrets management.
- Home Manager activation scripts are integrated for seamless secrets handling.

### Other Improvements
- **Typo Fix:** Corrected `pakages` to `packages` in `languages.nix`.
- **Documentation:** All changes and manual steps are reflected in the documentation.

### Next Steps
- Monitor Cursor for updates that may allow automated extension installation.
- Continue improving automation and reproducibility.
- Review and extend secrets management and editor tooling as needed.
- **[PRIORITY] Resolve non-functional Vim keybindings in Cursor.**

---

**Current Status:**
- VSIX download automation is in place for all extensions in `extensions.json`.
- Manual drag-and-drop installation is required for Cursor extensions.
- Documentation and secrets management are up to date.
- Project is progressing with a focus on reproducibility, automation, and clear documentation.
