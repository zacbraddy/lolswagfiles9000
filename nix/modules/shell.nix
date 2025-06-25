{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = lib.attrsets.mergeAttrsList [
      {
        gs = "git status";
        ga = "git add .";
        gc = "git commit";
        gp = "git push";
        gd = "git diff";
        gr = "git reset";
        reload = "exec zsh";
        netinfo = "ip a; iwconfig 2>/dev/null; nmcli device status";
        rm = "trash";
        cursor = "cursor-clean";  # Use the clean wrapper by default
      }
      (lib.optionalAttrs config.programs.direnv.enable {
        d = "direnv edit .";
      })
        ];
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "z"
        "sudo"
        "fzf"
        "history-substring-search"
        "extract"
        "colored-man-pages"
        "alias-finder"
        "docker"
        "node"
        "vi-mode"
      ];
    };
            initContent = ''
      # Set ZSH variable for oh-my-zsh (must be set before oh-my-zsh loads)
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"

      # Set FZF_BASE for oh-my-zsh compatibility
      export FZF_BASE="${pkgs.fzf}"

      # Safe AppImage environment cleanup with backup and user control
      # Only clean up problematic Python variables, leave PATH alone unless explicitly requested

      # Backup original PATH on first shell startup
      if [[ -z "$ORIGINAL_PATH_BACKUP" ]]; then
        export ORIGINAL_PATH_BACKUP="$PATH"
      fi

      # Detect if we're in a potentially problematic AppImage environment
      if [[ -n "$APPIMAGE" ]] || [[ -n "$APPDIR" ]]; then
        # Only clean up Python-related variables that cause the most problems
        # Leave PATH alone - it's too risky to modify automatically
        unset PYTHONHOME PYTHONPATH 2>/dev/null || true

        # Provide user-controlled cleanup functions
        appimage-cleanup() {
          echo "🧹 AppImage Environment Cleanup"
          echo "Current problematic variables:"
          echo "  APPIMAGE: ''${APPIMAGE:-[not set]}"
          echo "  APPDIR: ''${APPDIR:-[not set]}"
          echo "  PYTHONHOME: ''${PYTHONHOME:-[not set]}"
          echo "  PYTHONPATH: ''${PYTHONPATH:-[not set]}"
          echo
          echo "PATH backup: ''${ORIGINAL_PATH_BACKUP:-[not available]}"
          echo
          read -p "Clean up AppImage environment variables? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            unset PYTHONHOME PYTHONPATH APPIMAGE APPDIR 2>/dev/null || true
            echo "✅ AppImage environment variables cleaned"
          else
            echo "ℹ️  No changes made"
          fi
        }

        path-restore() {
          if [[ -n "$ORIGINAL_PATH_BACKUP" ]]; then
            echo "🔄 Restoring PATH from backup..."
            export PATH="$ORIGINAL_PATH_BACKUP"
            echo "✅ PATH restored"
          else
            echo "❌ No PATH backup available"
          fi
        }

        path-clean-appimage() {
          echo "⚠️  WARNING: This will modify your PATH variable"
          echo "Current PATH: $PATH"
          echo "Backup available: ''${ORIGINAL_PATH_BACKUP:-[none]}"
          read -p "Remove AppImage entries from PATH? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [[ ":$PATH:" =~ "\.AppImage" ]]; then
              PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '\.AppImage' | tr '\n' ':' | sed 's/:$//')
              export PATH
              echo "✅ AppImage entries removed from PATH"
              echo "Use 'path-restore' to restore if needed"
            else
              echo "ℹ️  No AppImage entries found in PATH"
            fi
          else
            echo "ℹ️  No changes made"
          fi
        }

        # Just notify, don't auto-clean
        if [[ "$SHELL_APPIMAGE_WARNING_SHOWN" != "1" ]]; then
          echo "⚠️  AppImage environment detected. Use 'appimage-cleanup' if you experience issues."
          export SHELL_APPIMAGE_WARNING_SHOWN=1
        fi
      fi

      # PATH modifications - safely append to existing PATH
      path_prepend() {
        if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
          export PATH="$1:$PATH"
        fi
      }

      path_append() {
        if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
          export PATH="$PATH:$1"
        fi
      }

      # Prepend user-local paths
      path_prepend "$HOME/.yarn/bin"
      path_prepend "$HOME/.config/yarn/global/node_modules/.bin"
      path_prepend "$HOME/.local/bin"
      path_prepend "$HOME/.poetry/bin"

      # Linuxbrew paths - only add if they exist
      if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        path_prepend "/home/linuxbrew/.linuxbrew/bin"
        path_prepend "/home/linuxbrew/.linuxbrew/sbin"
      fi

      # Flatpak exports for GUI applications accessible via CLI
      path_append "/var/lib/flatpak/exports/bin"
      path_append "$HOME/.local/share/flatpak/exports/bin"

      # Append spicetify path
      path_append "$HOME/.spicetify"

      # Initialize completions safely - fix permissions first
      if [[ -d "$HOME/.nix-profile/share/zsh/site-functions" ]]; then
        chmod -R go-w "$HOME/.nix-profile/share/zsh/site-functions" 2>/dev/null || true
      fi

      autoload -Uz compinit bashcompinit
      # Ignore insecure directories - common with Nix installations
      compinit -u
      bashcompinit

      # tabtab completions (Node.js tools)
      [ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true

      # Docker helper functions
      kadc() {
          docker ps -q | while read -r i; do docker stop $i; docker rm $i; done
      }
      explode_local_docker() {
          echo "=================== CONTAINERS ==================="
          docker ps -a
          echo "=============== CLEANING CONTAINERS =============="
          docker rm -f $(docker ps -aq 2>/dev/null || true)
          echo "================ CLEANING VOLUMES ================"
          docker volume prune -f
          echo "=================== CONTAINERS ==================="
          docker ps -a
      }

      # Project jump function
      pj() {
        local projects=($HOME/Projects/*)
        local project=$(printf "%s\n" "''${projects[@]}" | fzf --height 40% --reverse)
        if [[ -n "''${project}" ]]; then
          cd "''$project"
        fi
      }

      # Trash management helpers
      trash-clear-all() {
        trash-empty
      }
      trash-restore-last() {
        local last=$(trash-list | tail -n 1 | awk '{print $2}')
        if [[ -n "''${last}" ]]; then
          trash-restore "''$last"
        else
          echo "No files in trash to restore." >&2
        fi
      }
      trash-search() {
        if [ -z "''${1}" ]; then
          echo "Usage: trash-search <pattern>" >&2
          return 1
        fi
        trash-list | grep --color=auto "''$1"
      }
      trash-count() {
        trash-list | wc -l | awk '{print $1 " files in trash."}'
      }
      trash-empty-days() {
        if [ -z "''${1}" ]; then
          echo "Usage: trash-empty-days <days>" >&2
          return 1
        fi
        trash-empty "''$1"
      }

      # hmr function for Home Manager repair and reload
      hmr() {
        bash ~/Projects/Personal/lolswagfiles9000/scripts/hmr.sh "''${@}"
      }

      # Source powerlevel10k theme from Nix store if available
      if [ -d "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k" ]; then
        source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      fi

      # Load Powerlevel10k configuration
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # pnpm completion
      if type pnpm &>/dev/null; then
        source <(pnpm completion zsh)
      fi

      # nx completion (if installed via npm or globally)
      if type nx &>/dev/null; then
        source <(nx completion zsh || true)
      fi

      # --- Aider Integration: Functions ---
      find_aider_root() {
          # First check if AIDER_ROOT is already set
          if [ -n "$AIDER_ROOT" ] && [ -f "$AIDER_ROOT/pyproject.toml" ]; then
              echo "$AIDER_ROOT"
              return 0
          fi

          # Check common locations for aider setup
          local locations=(
              "$HOME/.aider"
              "$HOME/Projects/Personal/aider-setup"
              "$HOME/aider-setup"
          )

          for loc in "''${locations[@]}"; do
              if [ -d "$loc" ] && [ -f "$loc/pyproject.toml" ]; then
                  echo "$loc"
                  return 0
              fi
          done

          return 1
      }

      # Find git repository root
      find_git_root() {
          local dir="$PWD"
          while [ "$dir" != "/" ]; do
              if [ -d "$dir/.git" ]; then
                  echo "$dir"
                  return 0
              fi
              dir="$(dirname "$dir")"
          done
          return 1
      }

      # Find aider config files following aider's documented precedence
      find_aider_configs() {
          local git_root
          git_root="$(find_git_root)"

          local config_files=()

          # Add configs in aider's documented precedence order (later = higher priority)
          # 1. Home directory
          [ -f "$HOME/.aider.conf.yml" ] && config_files+=("$HOME/.aider.conf.yml")

          # 2. Git repo root
          if [ -n "$git_root" ] && [ -f "$git_root/.aider.conf.yml" ]; then
              config_files+=("$git_root/.aider.conf.yml")
          fi

          # 3. Current directory
          [ -f "$PWD/.aider.conf.yml" ] && config_files+=("$PWD/.aider.conf.yml")

          # Return all found configs (caller can use last one for highest priority)
          printf '%s\n' "''${config_files[@]}"
      }

      # Find aider .env files following aider's documented precedence
      find_aider_envs() {
          local git_root
          git_root="$(find_git_root)"

          local env_files=()

          # Add .env files in aider's documented precedence order (later = higher priority)
          # 1. Home directory
          [ -f "$HOME/.env" ] && env_files+=("$HOME/.env")

          # 2. Git repo root
          if [ -n "$git_root" ] && [ -f "$git_root/.env" ]; then
              env_files+=("$git_root/.env")
          fi

          # 3. Current directory
          [ -f "$PWD/.env" ] && env_files+=("$PWD/.env")

          # Return all found .env files (caller can use last one for highest priority)
          printf '%s\n' "''${env_files[@]}"
      }

      # Load configuration for aider according to its precedence rules (zsh compatible v3)
      load_aider_config() {
          local configs=() env_files=() line

          # Get all config files in precedence order (zsh compatible - no readarray)
          while IFS= read -r line; do
              [ -n "$line" ] && configs+=("$line")
          done < <(find_aider_configs)

          while IFS= read -r line; do
              [ -n "$line" ] && env_files+=("$line")
          done < <(find_aider_envs)

          # Process .env files first (lower priority than YAML)
          for env_file in "''${env_files[@]}"; do
              if [ -f "$env_file" ]; then
                  # Export environment variables from .env file
                  while IFS= read -r line || [ -n "$line" ]; do
                      # Skip comments and empty lines
                      [[ "$line" =~ ^[[:space:]]*# ]] && continue
                      [[ "$line" =~ ^[[:space:]]*$ ]] && continue

                      # Handle lines with = sign
                      if [[ "$line" =~ ^[^=]+= ]]; then
                          export "$line"
                      fi
                  done < "$env_file"
              fi
          done

          # Return the highest priority config file (last in the array)
          if [ ''${#configs[@]} -gt 0 ]; then
              echo "''${configs[-1]}"
          fi
      }

      # Main aider function with deepseek-chat model
      ai() {
        local aider_root="''$(find_aider_root)"
        local add_current_dir=true
        local args=()
        local config_file

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please set up aider in one of these locations:"
          echo "- $HOME/.aider"
          echo "- $HOME/Projects/Personal/aider-setup"
          echo "- $HOME/aider-setup"
          return 1
        fi

        # Load aider configuration according to its precedence rules
        config_file="$(load_aider_config)"

        # Check if user provided --file or directory arguments
        for arg in "$@"; do
          if [[ "$arg" == "--file" ]] || [[ "$arg" == "-f" ]] || [[ -d "$arg" ]] || [[ -f "$arg" ]]; then
            add_current_dir=false
            break
          fi
        done

        # Build arguments array
        if [ "$add_current_dir" = true ]; then
          args+=("''$(pwd)")
        fi

        # Add config file if found
        if [ -n "$config_file" ]; then
          args+=("--config" "$config_file")
        fi

        # Add model specification (can be overridden by config file or user args)
        args+=("--model" "deepseek/deepseek-chat")
        args+=("$@")

        poetry -P="''${aider_root}" run aider "''${args[@]}"
      }

      # Aider function with deepseek-r1 model
      air1() {
        local aider_root="''$(find_aider_root)"
        local add_current_dir=true
        local args=()
        local config_file

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please set up aider in one of these locations:"
          echo "- $HOME/.aider"
          echo "- $HOME/Projects/Personal/aider-setup"
          echo "- $HOME/aider-setup"
          return 1
        fi

        # Load aider configuration according to its precedence rules
        config_file="$(load_aider_config)"

        # Check if user provided --file or directory arguments
        for arg in "$@"; do
          if [[ "$arg" == "--file" ]] || [[ "$arg" == "-f" ]] || [[ -d "$arg" ]] || [[ -f "$arg" ]]; then
            add_current_dir=false
            break
          fi
        done

        # Build arguments array
        if [ "$add_current_dir" = true ]; then
          args+=("''$(pwd)")
        fi

        # Add config file if found
        if [ -n "$config_file" ]; then
          args+=("--config" "$config_file")
        fi

        # Add model specification (can be overridden by config file or user args)
        args+=("--model" "deepseek/deepseek-r1")
        args+=("$@")

        poetry -P="''${aider_root}" run aider "''${args[@]}"
      }

      # Aider status and configuration information
      ai-status() {
        local current_aider_root="''$(find_aider_root)"
        local target_dir="''$(pwd)"
        local git_root="''$(find_git_root)"

        echo "=== Current Configuration ==="
        echo "Current Directory: $target_dir"
        echo "Git Root: ''${git_root:-[not in git repo]}"
        echo "Aider Root: ''${current_aider_root:-[not found]}"

        if [ -z "$current_aider_root" ]; then
          echo "❌ No valid aider setup found!"
          echo "Please set up aider in one of these locations:"
          echo "- $HOME/.aider"
          echo "- $HOME/Projects/Personal/aider-setup"
          echo "- $HOME/aider-setup"
          return 1
        fi

        echo
        echo "=== Configuration Files (Aider's precedence order) ==="

        # Show all config files that would be loaded (zsh compatible v3)
        local configs=() env_files=() line

        # Get all config files in precedence order (zsh compatible - no readarray)
        while IFS= read -r line; do
            [ -n "$line" ] && configs+=("$line")
        done < <(find_aider_configs)

        while IFS= read -r line; do
            [ -n "$line" ] && env_files+=("$line")
        done < <(find_aider_envs)

        # Show .env files
        echo "📄 .env files (loaded first, lower precedence):"
        if [ ''${#env_files[@]} -eq 0 ]; then
          echo "  - No .env files found"
        else
          for env_file in "''${env_files[@]}"; do
            echo "  ✅ $env_file"
          done
          echo "  📌 Active .env: ''${env_files[-1]:-[none]}"
        fi

        echo
        echo "📄 YAML config files (loaded last, higher precedence):"
        if [ ''${#configs[@]} -eq 0 ]; then
          echo "  - No .aider.conf.yml files found"
        else
          for config in "''${configs[@]}"; do
            echo "  ✅ $config"
          done
          echo "  📌 Active config: ''${configs[-1]:-[none]}"
        fi

        echo
        echo "=== Effective Configuration ==="

        # Temporarily load config to show what would actually be used
        local original_env
        original_env="$(env | grep -E '^(DEEPSEEK_API_KEY|AIDER_|OPENAI_|ANTHROPIC_)' | sort)"

        # Load configuration (this exports environment variables)
        local active_config
        active_config="$(load_aider_config)"

        # Show the configuration that would be used
        echo "🔧 Configuration that would be used by ai/air1 commands:"
        echo

        # API Keys
        echo "API Keys:"
        if [ -n "''${DEEPSEEK_API_KEY:-}" ]; then
          echo "  DEEPSEEK_API_KEY: [SET]"
        else
          echo "  DEEPSEEK_API_KEY: [NOT SET]"
        fi

        if [ -n "''${OPENAI_API_KEY:-}" ]; then
          echo "  OPENAI_API_KEY: [SET]"
        else
          echo "  OPENAI_API_KEY: [NOT SET]"
        fi

        if [ -n "''${ANTHROPIC_API_KEY:-}" ]; then
          echo "  ANTHROPIC_API_KEY: [SET]"
        else
          echo "  ANTHROPIC_API_KEY: [NOT SET]"
        fi

        echo
        echo "Aider Settings:"
        echo "  Model (ai command): ''${AIDER_MODEL:-deepseek/deepseek-chat}"
        echo "  Model (air1 command): deepseek/deepseek-r1"
        echo "  Config file: ''${active_config:-[none - using defaults]}"
        echo "  Edit format: ''${AIDER_EDIT_FORMAT:-[default]}"
        echo "  Auto commits: ''${AIDER_AUTO_COMMITS:-true}"
        echo "  Dark mode: ''${AIDER_DARK_MODE:-false}"
        echo "  Stream: ''${AIDER_STREAM:-true}"

        if [ -n "$active_config" ] && command -v yq >/dev/null 2>&1; then
          echo
          echo "🔍 Active YAML config contents:"
          yq -r 'to_entries | .[] | select(.value != null and .value != "") | "\(.key): \(.value)"' "$active_config" 2>/dev/null | sed 's/^/  /' || echo "  Could not parse YAML config"
        fi

        echo
        echo "=== Command Preview ==="
        echo "🚀 Commands that would be executed:"

        local cmd_args=()
        if [ -n "$active_config" ]; then
          cmd_args+=("--config" "$active_config")
        fi

        echo "  ai:   poetry -P=\"$current_aider_root\" run aider ''${cmd_args[*]} --model deepseek/deepseek-chat [your-args]"
        echo "  air1: poetry -P=\"$current_aider_root\" run aider ''${cmd_args[*]} --model deepseek/deepseek-r1 [your-args]"

        echo
        echo "=== Version Information ==="
        echo -n "Poetry: "
        poetry --version 2>/dev/null || echo "Not available"
        echo -n "Aider: "
        (cd "$current_aider_root" && poetry run aider --version 2>/dev/null) || echo "Could not get aider version"
        echo -n "yq: "
        yq --version 2>/dev/null || echo "Not available (needed for YAML config parsing)"
      }


      # --- Aider Integration: Setup ---
      if [ -n "''$(find_aider_root)" ]; then
          export AIDER_ROOT="''$(find_aider_root)"
      fi
    '';
  };
  # Enable fzf globally with zsh integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  # Ensure required tools are installed for completions
  home.packages = with pkgs; [
    # Core tools
    fzf
    trash-cli
    just
    yq-go

    # Development tools
    nodejs
    pnpm
    yarn
    poetry
    docker

    # Shell enhancements
    zsh-powerlevel10k
    oh-my-zsh
    asdf

    # System utilities
    getent
    which
    coreutils
    gnused
    gawk
    findutils
    gnugrep

    # Optional tools
    spicetify-cli

    # Cursor wrapper script to prevent AppImage environment pollution
    (pkgs.writeShellScriptBin "cursor-clean" ''
      #!/bin/bash
      # Clean wrapper for Cursor AppImage to prevent environment hijacking

      # Find the Cursor AppImage
      CURSOR_APPIMAGE="$HOME/.local/bin/cursor.AppImage"

      if [[ ! -f "$CURSOR_APPIMAGE" ]]; then
        echo "Error: Cursor AppImage not found at $CURSOR_APPIMAGE"
        echo "Please run 'just install-cursor' first"
        exit 1
      fi

      # Clean environment variables that cause conflicts
      unset PYTHONHOME PYTHONPATH APPIMAGE APPDIR

      # Clean any AppImage-injected PATH entries
      if [[ ":$PATH:" =~ "\.AppImage" ]]; then
        PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '\.AppImage' | tr '\n' ':' | sed 's/:$//')
        export PATH
      fi

      # Launch Cursor with clean environment and no-sandbox flag
      exec "$CURSOR_APPIMAGE" --no-sandbox "$@"
    '')
  ];
    # Managed dotfiles
  home.file.".p10k.zsh".source = ../../zsh/.p10k.zsh;
  home.file.".gitconfig".source = ../../.gitconfig;
  home.file.".gitignore_global".source = ../../.gitignore_global;
  home.file.".ideavimrc".source = ../../.ideavimrc;
  # Direnv integration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  # Home Manager session variables
  home.sessionVariables = {
    EDITOR = "vim";
    BROWSER = "brave";
  };
  # Powerlevel10k: show exit status of last command in prompt (if not already configured)
  # If you want a custom symbol, add to your ~/.p10k.zsh:
  # typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status ...)
}
