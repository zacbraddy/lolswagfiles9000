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

- [ ] Design and implement CLI wizard (Justfile or similar)
  - Core Features:
    1. Initial Setup
       - System requirements check
       - Home Manager installation verification
       - Directory structure creation
    2. Secrets Management
       - Read required secrets from `secrets.nix`
       - Check for missing secrets in `secrets.yaml`
       - Guide user through setting up each required secret
       - Validate secret setup completion
    3. Module Configuration
       - Interactive module selection
      4. Post-Setup
       - System validation
       - Next steps guidance
       - Troubleshooting information

- [ ] Test full rebuild and rollback process
  - Document step-by-step process
  - Test on fresh system
  - Verify all components work
  - Document rollback procedures

- [ ] Design and implement persistent file sync/backup solution
  - Research options (Google Drive, cloud sync)
  - Implement automated sync for important files
  - Document sync process and exclusions

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
**Next**: Begin CLI wizard implementation

## Recent Progress

- **2025-06-13:** Improved Cursor settings management with diff/merge capability
- **2025-06-12:** Completed Ansible migration
- **2025-06-03:** Automated Cursor and Adobe Reader installation
- **2025-06-02:** Completed zsh configuration migration
- **2025-06-01:** Implemented Home Manager activation scripts
