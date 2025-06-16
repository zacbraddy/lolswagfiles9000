# Dotfiles Implementation Plan

## Project Protocol

- **Goal**: Create a perfect development environment that allows machine rebuild at a moment's notice
- **Focus**: Reliability, automation, and easy ongoing updates
- **Approach**: Interview → Plan → Implement
- **Interview Style**: ONE question at a time, prefer yes/no or short answers
- **Artifact Usage**: Track progress, goals, and implementation plan across multiple chat sessions
- **Assistant Change Protocol**: The assistant will make changes directly without asking for permission. The user will request rollbacks if any changes are incorrect.
- **Documentation Check**: Always confirm Home Manager and Nix configuration changes against the official documentation before suggesting or applying them.

## Outstanding Tasks

- [x] Design and implement CLI wizard (Justfile or similar)
  - Core Features:
    1. Initial Setup
       - [x] System requirements check
       - [x] Home Manager installation verification
       - [x] Directory structure creation
    2. Secrets Management
       - [x] Read required secrets from `secrets.nix`
       - [x] Check for missing secrets in `secrets.yaml`
       - [x] Guide user through setting up each required secret
       - [x] Validate secret setup completion
    3. Post-Setup
       - [x] System validation
       - [x] Next steps guidance
       - [ ] Troubleshooting information

- [ ] Design and implement persistent file sync/backup solution
  - [ ] Research options (Google Drive, cloud sync)
  - [ ] Implement automated sync for important files
  - [ ] Document sync process and exclusions

- [x] Migrate camera-fix service management to script-based approach (install-camera-fix-service.sh) and remove Nix/Home Manager systemd integration for this service
- [x] Remove redundant Cursor settings file from nix/modules; settings are now managed only in .config/Cursor/User/settings.json
- [x] Ensure all scripts in scripts/ are executable and tracked in git for reproducibility
- [ ] Test full rebuild process
  - [ ] Document step-by-step process
  - [ ] Test on fresh system
  - [ ] Verify all components work

## Implementation Notes

### Justfile Best Practices
1. **Multi-line Recipes:**
   - Each line must end with a backslash (`\`), except the last line
   - Use exactly four spaces (no tabs) for indentation under 'script:'
   - Check for invisible characters and ensure consistent indentation

2. **Argument Passing:**
   - Use `$name` (not `$1` or `name="$1"`) for named arguments
   - Always use single `$` for shell variable expansion (not `$$`)
   - Use `${name:-}` for default values if needed

3. **Error Handling:**
   - Always check for errors in command execution
   - Provide clear error messages
   - Use `set -x` for debugging

### Home Manager Best Practices
- Always use flake-based Home Manager commands (e.g., 'home-manager switch --flake .#zacbraddy')
- Home Manager may return non-zero exit code after activation even if successful
- Check official documentation before suggesting changes

### Cursor Editor Management
- Extension installation is managed via recommendations
- Settings are copied (not symlinked) with diff/merge capability
- Manual drag-and-drop installation required for extensions
- Document all manual steps in setup guide
- **Status:** All Cursor installation and sync issues are now resolved. No further troubleshooting required for Cursor.

### Obsidian Configuration Management
- Obsidian is installed via Nix and included in home.packages
- Configuration files are managed in obsidian/ directory at repo root:
  - app.json (theme and appearance settings)
  - appearance.json (UI customization)
  - community-plugins.json (plugin list)
  - core-plugins.json (core plugin settings)
  - workspace.json (layout and state)
  - vimrc (vim keybindings)
- Plugin management:
  - Vim plugins (obsidian-vimrc-support, surround, commentary, easymotion, highlightedyank, which-key)
  - Utility plugins (advanced-tables, quick-switcher-plus-plus, tag-wrangler, paste-url-into-selection)
- Sync process:
  - Two-way sync between dotfiles and vaults
  - Automatic plugin installation and configuration
  - Workspace state preservation
  - Theme and appearance synchronization

## Current Status

**Phase**: Implementation - In Progress 🚀
**Next**: Smart Connections Integration and Vault Organization

## Recent Progress

- **2025-06-13:**
  - Completed CLI wizard implementation with proper error handling
  - Fixed Home Manager exit code handling in setup wizard
  - Cursor installation and sync issues are now fully resolved
  - Camera-fix service is now managed by a shell script (install-camera-fix-service.sh) called from the Justfile/setup-wizard. Nix/Home Manager no longer manages this systemd service due to persistent issues with user unit generation. All system tweaks are now handled by scripts, not Nix modules. Redundant Cursor settings file in nix/modules was removed; settings are now managed only in .config/Cursor/User/settings.json. All scripts in scripts/ are now executable and tracked in git for reproducibility.
  - **Obsidian is now managed via Nix and dotfiles:**
    - Obsidian is installed via Nix and included in home.packages.
    - All key config files (appearance.json, community-plugins.json, core-plugins.json, workspace.json, vimrc) are managed in an obsidian/ directory at the repo root and symlinked into ~/.config/obsidian/.
    - Vim keybindings and plugins (obsidian-vimrc-support, surround, commentary, easymotion, highlightedyank, which-key) are enabled and managed.
    - advanced-tables and other useful plugins (quick-switcher-plus-plus, tag-wrangler, paste-url-into-selection) are included in community-plugins.json.
    - A just sync-obsidian-settings recipe was added, mirroring the Cursor workflow, and integrated into setup-wizard.
    - Only .vscode/extensions.json is now managed as the source of truth for extensions; .config/Cursor/User/extensions.json is no longer tracked in dotfiles.
- **2025-06-12:** Completed Ansible migration
- **2025-06-03:** Automated Cursor and Adobe Reader installation
- **2025-06-02:** Completed zsh configuration migration
- **2025-06-01:** Implemented Home Manager activation scripts


1. **Cursor Settings Management**
   - Moved from project-level to global settings
   - Updated `scripts/install-cursor.sh` to handle global settings
   - Updated `nix/modules/editors.nix` to use global settings
   - Simplified `justfile` Cursor-related recipes
   - Kept `.vscode/extensions.json` for extension bootstrapping

2. **Configuration File Review**
   - Confirmed `tuxedo_keyboard.conf` is still needed for Tuxedo laptop keyboard configuration
   - Verified `default.pa` is actively used for PulseAudio configuration
   - Both files are properly linked through Nix configuration

3. **Obsidian Configuration Management**
   - Created scripts for managing multiple vaults
   - Implemented configuration sync between vaults
   - Set up plugin management
   - Configured theme and appearance settings
   - Added vim keybindings support
   - Implemented workspace synchronization


### Troubleshooting Note
- Systemd user services managed by Home Manager may not always be reliably generated or enabled, especially in complex or flake-based setups. If a service is not appearing or being enabled, prefer a script-based approach for critical system tweaks. This is now the default for camera-fix and similar services in this repo.
