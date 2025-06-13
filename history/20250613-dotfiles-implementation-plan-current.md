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

- [ ] Test full rebuild and rollback process
  - [ ] Document step-by-step process
  - [ ] Test on fresh system
  - [ ] Verify all components work
  - [ ] Document rollback procedures

- [ ] Design and implement persistent file sync/backup solution
  - [ ] Research options (Google Drive, cloud sync)
  - [ ] Implement automated sync for important files
  - [ ] Document sync process and exclusions

- [x] Migrate camera-fix service management to script-based approach (install-camera-fix-service.sh) and remove Nix/Home Manager systemd integration for this service
- [x] Remove redundant Cursor settings file from nix/modules; settings are now managed only in .config/Cursor/User/settings.json
- [x] Ensure all scripts in scripts/ are executable and tracked in git for reproducibility

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

## Current Status

**Phase**: Implementation - In Progress 🚀
**Next**: Address Cursor installation issues and complete troubleshooting information

## Recent Progress

- **2025-06-13:**
  - Completed CLI wizard implementation with proper error handling
  - Fixed Home Manager exit code handling in setup wizard
  - Identified Cursor installation issues to resolve
  - Camera-fix service is now managed by a shell script (install-camera-fix-service.sh) called from the Justfile/setup-wizard. Nix/Home Manager no longer manages this systemd service due to persistent issues with user unit generation. All system tweaks are now handled by scripts, not Nix modules. Redundant Cursor settings file in nix/modules was removed; settings are now managed only in .config/Cursor/User/settings.json. All scripts in scripts/ are now executable and tracked in git for reproducibility.
- **2025-06-12:** Completed Ansible migration
- **2025-06-03:** Automated Cursor and Adobe Reader installation
- **2025-06-02:** Completed zsh configuration migration
- **2025-06-01:** Implemented Home Manager activation scripts

## Next Session Goals

1. Fix Cursor installation issues:
   - Investigate `home-manager-update` failure
   - Debug `sync-cursor-settings` error
   - Implement proper error handling for Cursor-related commands

2. Complete troubleshooting information:
   - Document common issues and solutions
   - Create recovery procedures
   - Add verbose logging options

## ✅ Completed Tasks

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

## 📋 Next Session: Vim Keybindings Refinement

1. **Current Vim Configuration Review**
   - Review existing keybindings in `.ideavimrc` and Cursor settings
   - Identify areas for improvement or optimization
   - Consider consistency across different editors (Cursor, JetBrains IDEs)

2. **Keybinding Categories to Review**
   - Navigation and movement
   - Text manipulation and editing
   - Window/tab management
   - Search and replace
   - Leader key mappings
   - Custom commands and macros

3. **Potential Improvements**
   - Streamline common operations
   - Add missing functionality
   - Ensure ergonomic key combinations
   - Consider adding new leader key mappings
   - Review and optimize existing mappings

4. **Documentation**
   - Document new/changed keybindings
   - Create a quick reference guide
   - Add comments in configuration files

### Troubleshooting Note
- Systemd user services managed by Home Manager may not always be reliably generated or enabled, especially in complex or flake-based setups. If a service is not appearing or being enabled, prefer a script-based approach for critical system tweaks. This is now the default for camera-fix and similar services in this repo.
