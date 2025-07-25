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
  - plugins/ directory with 34+ community plugins and configurations
  - themes/ directory with custom themes (Dracula Official)
  - icons/ directory for icon configurations
- **New Vault Management System (2025-07-25):**
  - **No automatic sync**: Removed obsidian sync from hmr process
  - **Global commands**: Added `ob-create`, `ob-update`, `ob-refresh-dotfiles` available from any directory
  - **Configuration tracking**: Uses `~/.obsidian/config` to store dotfiles path (no hardcoded paths)
  - **Managed vaults list**: Tracks all managed vaults in `~/.obsidian/managed-vaults.txt`
  - **Smart plugin filtering**: Only syncs essential plugin files, excludes runtime data:
    - ✅ Syncs: `main.js`, `manifest.json`, `styles.css`, `data.json` (configuration)
    - ❌ Excludes: `histories.json`, `cursor-positions.json`, SSL certificates, cache files, logs
    - Uses pattern-based filtering for future-proof plugin management
- Commands:
  - `ob-create <vault-name>`: Creates new vault with all dotfiles settings
  - `ob-update`: Updates current vault with fresh dotfiles settings  
  - `ob-refresh-dotfiles`: Updates dotfiles with current vault settings (smart filtering applied)

## Current Status

**Phase**: Implementation - In Progress 🚀
**Next**: Smart Connections Integration and Vault Organization

## Recent Progress

- **2025-06-13:**
  - Completed CLI wizard implementation with proper error handling
  - Fixed Home Manager exit code handling in setup wizard
  - Cursor installation and sync issues are now fully resolved
  - Camera-fix service is now managed by a shell script (install-camera-fix-service.sh) called from the Justfile/setup-wizard. Nix/Home Manager no longer manages this systemd service due to persistent issues with user unit generation. All system tweaks are now handled by scripts, not Nix modules. Redundant Cursor settings file in nix/modules was removed; settings are now managed only in .config/Cursor/User/settings.json. All scripts in scripts/ are now executable and tracked in git for reproducibility.
  - **Obsidian vault management system redesigned (2025-07-25):**
    - Removed automatic obsidian sync from hmr process for better control
    - Implemented new vault manager (`scripts/obsidian/vault-manager.js`) with smart plugin filtering
    - Added global zsh commands: `ob-create`, `ob-update`, `ob-refresh-dotfiles`
    - Configuration now uses `~/.obsidian/config` to track dotfiles path (no hardcoded paths)
    - Smart filtering excludes runtime data (histories, cursor positions, SSL certs) but keeps configs
    - Pattern-based exclusion system future-proofs against new plugin runtime data
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

## Obsidian Management Notes

**Legacy sync commands removed (2025-07-25):**
- `just obsidian-sync` has been removed from the hmr process
- Old vault sync commands are deprecated in favour of new global commands

**New workflow:**
- Use `ob-create <vault-name>` to create new vaults with dotfiles settings
- Use `ob-update` from within a vault to refresh it with dotfiles settings
- Use `ob-refresh-dotfiles` from within a vault to update dotfiles with current vault settings
- All commands use smart filtering to exclude runtime data and sensitive files

## Home Manager caching issues

If you encounter an issue where you're trying to update the .zshrc then you might find that it refuses to overwrite. To fix this run `just clear-nix-cache` and try again.
If that doesn't work, I have no idea what is wrong!
