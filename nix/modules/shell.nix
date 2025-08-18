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
      #export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"

      # Set FZF_BASE for oh-my-zsh compatibility
      export FZF_BASE="${pkgs.fzf}"

      # If anything happens to the path we can restore the last one
      export ORIGINAL_PATH_BACKUP="$PATH"

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

      # Create p10k aliases after Powerlevel10k is loaded
      alias p10k-down="prompt_powerlevel9k_teardown"
      alias p10k-up="prompt_powerlevel9k_setup"

      # Fix to make it so that cursor integrated terminal runs without p10k so it doesn't hang
      if [[ -n $CURSOR_TRACE_ID ]]; then
        p10k-down
      fi

      # Set automation flag for VS Code/Cursor integrated terminals
      if [[ -n "$TERM_PROGRAM" ]] && [[ "$TERM_PROGRAM" == "vscode" ]]; then
        export I_AM_AUTOMATED_CURSOR_TERM=1
      fi

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
          local aider_root
          aider_root="$(find_aider_root)"

          local env_files=()

          if [ -n "$aider_root" ] && [ -f "$aider_root/.env" ]; then
              env_files+=("$aider_root/.env")
          fi

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

      # Generic aider function that takes model as parameter
      _aider_with_model() {
        local model="$1"
        shift  # Remove first argument (model) from $@

        local aider_root="$(find_aider_root)"
        local config_file

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          return 1
        fi

        # Source .env from aider root if it exists
        if [ -f "$aider_root/.env" ]; then
          set -a
          source "$aider_root/.env"
          set +a
        fi

        config_file="$(load_aider_config)"

        # Filter out --model flags from the arguments
        # We'll rebuild the argument list in $@ by using set --
        local temp_args=""
        local skip_next=false

        for arg in "$@"; do
          if [ "$skip_next" = true ]; then
            skip_next=false
            echo "Warning: --model flag ignored. Use 'ai' for deepseek-chat or 'air1' for deepseek-r1"
            continue
          fi

          case "$arg" in
            --model)
              skip_next=true
              echo "Warning: --model flag ignored. Use 'ai' for deepseek-chat or 'air1' for deepseek-r1"
              continue
              ;;
            --model=*)
              echo "Warning: --model flag ignored. Use 'ai' for deepseek-chat or 'air1' for deepseek-r1"
              continue
              ;;
            *)
              # Preserve the argument exactly as passed
              if [ -z "$temp_args" ]; then
                temp_args="$arg"
              else
                temp_args="$temp_args"$'\n'"$arg"
              fi
              ;;
          esac
        done

        echo "Starting aider with model: $model"

        # Rebuild $@ with filtered arguments
        set --
        if [ -n "$temp_args" ]; then
          # Use process substitution to handle arguments with spaces/special chars
          while IFS= read -r line; do
            set -- "$@" "$line"
          done <<< "$temp_args"
        fi

        # Execute directly without eval
        if [ -n "$config_file" ]; then
          poetry -P="$aider_root" run aider --model "$model" --config "$config_file" "$@"
        else
          poetry -P="$aider_root" run aider --model "$model" "$@"
        fi
      }

      # Specific model functions
      ai() {
        _aider_with_model "deepseek/deepseek-chat" "$@"
      }

      air1() {
        _aider_with_model "deepseek/deepseek-reasoner" "$@"
      }

      # Aider status and configuration information
      ai-status() {
        local current_aider_root="''$(find_aider_root)"
        local target_dir="''$(pwd)"
        local git_root="''$(find_git_root)"

        # Source .env from aider root if it exists
        if [ -n "$current_aider_root" ] && [ -f "$current_aider_root/.env" ]; then
          set -a
          source "$current_aider_root/.env"
          set +a
        fi

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

        if [ -n "$active_config" ] && command -v ${pkgs.yq-go}/bin/yq >/dev/null 2>&1; then
          echo
          echo "🔍 Active YAML config contents:"
          ${pkgs.yq-go}/bin/yq -r 'to_entries | .[] | select(.value != null and .value != "") | "\(.key): \(.value)"' "$active_config" 2>/dev/null | sed 's/^/  /' || echo "  Could not parse YAML config"
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
        ${pkgs.yq-go}/bin/yq --version 2>/dev/null || echo "Not available (needed for YAML config parsing)"
      }

      # --- Aider Integration: Setup ---
      if [ -n "''$(find_aider_root)" ]; then
          export AIDER_ROOT="''$(find_aider_root)"
      fi

      # --- Obsidian Vault Management ---
      _get_dotfiles_vault_manager() {
        local config_file="$HOME/.obsidian/config"
        if [ -f "$config_file" ]; then
          local dotfiles_path=$(grep '^DOTFILES_PATH=' "$config_file" | cut -d'=' -f2)
          if [ -n "$dotfiles_path" ] && [ -f "$dotfiles_path/scripts/obsidian/vault-manager.js" ]; then
            echo "$dotfiles_path/scripts/obsidian/vault-manager.js"
            return 0
          fi
        fi
        echo "❌ Could not find obsidian vault manager. Run 'hmr' to initialise." >&2
        return 1
      }

      ob-create() {
        if [ -z "$1" ]; then
          echo "Usage: ob-create <vault-name>"
          echo "Example: ob-create MyNewVault"
          return 1
        fi

        local vault_name="$1"
        local vault_path="$PWD/$vault_name"
        local vault_manager

        if ! vault_manager=$(_get_dotfiles_vault_manager); then
          return 1
        fi

        node "$vault_manager" create "$vault_path"
      }

      ob-update() {
        local vault_path="$PWD"
        local vault_manager

        if [ ! -d "$vault_path/.obsidian" ]; then
          echo "❌ No .obsidian directory found in current directory: $vault_path"
          echo "This command must be run from an Obsidian vault directory."
          return 1
        fi

        if ! vault_manager=$(_get_dotfiles_vault_manager); then
          return 1
        fi

        node "$vault_manager" update "$vault_path"
      }

      ob-refresh-dotfiles() {
        local vault_path="$PWD"
        local vault_manager

        if [ ! -d "$vault_path/.obsidian" ]; then
          echo "❌ No .obsidian directory found in current directory: $vault_path"
          echo "This command must be run from an Obsidian vault directory."
          return 1
        fi

        if ! vault_manager=$(_get_dotfiles_vault_manager); then
          return 1
        fi

        node "$vault_manager" refresh "$vault_path"
      }

      # --- Filestore Management ---
      _get_filestore_script() {
        local script_name="$1"
        local config_file="$HOME/.obsidian/config"
        if [ -f "$config_file" ]; then
          local dotfiles_path=$(grep '^DOTFILES_PATH=' "$config_file" | cut -d'=' -f2)
          if [ -n "$dotfiles_path" ] && [ -f "$dotfiles_path/scripts/backup/$script_name" ]; then
            echo "$dotfiles_path/scripts/backup/$script_name"
            return 0
          fi
        fi
        # Fallback to hardcoded path if config not found
        local fallback_path="$HOME/Projects/Personal/lolswagfiles9000/scripts/backup/$script_name"
        if [ -f "$fallback_path" ]; then
          echo "$fallback_path"
          return 0
        fi
        echo "❌ Could not find filestore script: $script_name. Run 'hmr' to initialize." >&2
        return 1
      }

      bk-sync() {
        local script_path
        if ! script_path=$(_get_filestore_script "sync-filestore.sh"); then
          return 1
        fi
        bash "$script_path" "''${1:-sync}"
      }

      bk-status() {
        local script_path
        if ! script_path=$(_get_filestore_script "sync-filestore.sh"); then
          return 1
        fi
        bash "$script_path" status
      }

      bk-pull() {
        local script_path
        if ! script_path=$(_get_filestore_script "sync-filestore.sh"); then
          return 1
        fi
        bash "$script_path" pull
      }
    '';
  };

  # Install and configure Spicetify for Spotify customisation
  home.activation.setupSpicetify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create spicetify directory structure
    $DRY_RUN_CMD mkdir -p ~/.spicetify/Themes
    $DRY_RUN_CMD mkdir -p ~/.spicetify/Extensions
    $DRY_RUN_CMD mkdir -p ~/.spicetify/CustomApps
    $DRY_RUN_CMD mkdir -p ~/.spicetify/jsHelper

    # Install popular Spicetify themes if not already present
    if [ ! -d ~/.spicetify/Themes/SpicetifyDefault ] && command -v spicetify >/dev/null 2>&1; then
      echo "Installing Spicetify default theme..."
      $DRY_RUN_CMD spicetify theme apply 2>/dev/null || echo "Theme installation will complete when Spotify is first launched"
    fi

    # Run spicetify backup and apply (only if spotify is installed)
    if command -v spotify >/dev/null 2>&1 || [ -d ~/.config/spotify ] || flatpak list | grep -q spotify; then
      $DRY_RUN_CMD spicetify backup apply 2>/dev/null || echo "Spicetify setup will complete when Spotify is first launched"
    fi
  '';

  # Enable fzf globally with zsh integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    # Core tools
    fzf
    trash-cli
    just
    yq-go
    ranger

    # Development tools
    nodejs
    pnpm
    yarn
    poetry
    docker
    azure-cli

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
    # Native libraries for node-canvas and image processing
    cairo
    pango
    libjpeg
    gtk3
    (lib.hiPrio gdk-pixbuf)
    librsvg
    gdk-pixbuf
    giflib
    libuuid
    pkg-config
  ];

  home.file.".p10k.zsh".source = ../../zsh/.p10k.zsh;
  home.file.".gitconfig".source = ../../.gitconfig;
  home.file.".gitignore_global".source = ../../.gitignore_global;
  home.file.".ideavimrc".source = ../../.ideavimrc;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "vim";
    BROWSER = "brave";
  };
}
