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
        # pnpm, turbo, nx, and moonrepo completions handled below
        # Temporarily disable all plugins to isolate the error
        # Re-enable one by one after confirmation
      ];
    };
    initContent = ''
      ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$HOST-$ZSH_VERSION"
      mkdir -p "$ZSH_CACHE_DIR"
      chmod 700 "$ZSH_CACHE_DIR"
      if [[ ! -f "$ZSH_COMPDUMP" ]]; then
        touch "$ZSH_COMPDUMP"
        chmod 600 "$ZSH_COMPDUMP"
      fi

      # Build our expected PATH
      EXPECTED_PATHS=(
        "/usr/local/sbin"
        "/usr/local/bin"
        "/usr/sbin"
        "/usr/bin"
        "/sbin"
        "/bin"
        "/usr/games"
        "/usr/local/games"
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.local/share/nvim/mason/bin"
        "$HOME/.npm-global/bin"
        "$HOME/.yarn/bin"
        "$HOME/.config/yarn/global/node_modules/.bin"
        "$HOME/.poetry/bin"
        "$HOME/.asdf/shims"
        "$HOME/.asdf/bin"
        "$HOME/.spicetify"
        "$HOME/.linuxbrew/bin"
        "/home/linuxbrew/.linuxbrew/bin"
      )

      # Add Nix paths if they exist
      [ -d "$HOME/.nix-profile/bin" ] && EXPECTED_PATHS+=("$HOME/.nix-profile/bin")
      [ -d "/nix/var/nix/profiles/default/bin" ] && EXPECTED_PATHS+=("/nix/var/nix/profiles/default/bin")
      [ -d "/run/current-system/sw/bin" ] && EXPECTED_PATHS+=("/run/current-system/sw/bin")

      # Build expected PATH string
      EXPECTED_PATH=""
      for p in "''${EXPECTED_PATHS[@]}"; do
        if [ -d "$p" ]; then
          EXPECTED_PATH="$EXPECTED_PATH:$p"
        fi
      done
      EXPECTED_PATH="''${EXPECTED_PATH#:}"

      # Compare with current PATH
      if [[ ":$PATH:" != *":$EXPECTED_PATH:"* ]]; then
        echo "⚠️  Warning: Your PATH differs from the Nix-managed configuration"
        echo "   Current PATH contains entries not managed by Nix"
        echo "   To fix this, add the following to your shell.nix home.packages:"
        echo

        # Find unmanaged paths
        IFS=: read -ra CURRENT_PATHS <<< "$PATH"
        for p in "''${CURRENT_PATHS[@]}"; do
          if [[ -n "$p" && -d "$p" && ":$EXPECTED_PATH:" != *":$p:"* ]]; then
            echo "   - ''${pkgs.writeShellScriptBin "path-$(basename \"$p\")" ''"
              # This would be the package that provides this path
              echo "Warning: Adding unmanaged path to PATH: ''$p" >&2
              if [[ -d "''$p" ]]; then
                export PATH="''$PATH:''$p"
              else
                echo "Error: Path does not exist: ''$p" >&2
                return 1
              fi
            "''}"
          fi
        done

        echo
        echo "   Using current PATH to avoid losing functionality"
      else
        export PATH="$EXPECTED_PATH"
      fi

      # Initialize completions safely
      autoload -Uz compinit bashcompinit
      if [[ -n "$ZSH_COMPDUMP" ]] && [[ -w "$(dirname "$ZSH_COMPDUMP")" ]]; then
        compinit -d "$ZSH_COMPDUMP"
      else
        compinit -C
      fi
      bashcompinit
      # tabtab completions (Node.js tools)
      [ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true
      # Docker helper functions
      kadc() {
          docker ps -q | while read -r i; do docker stop ''$i; docker rm ''$i; done
      }
      explode_local_docker() {
          echo "=================== CONTAINERS ==================="
          docker ps -a
          echo "=============== CLEANING CONTAINERS =============="
          docker rm -f ''$(docker ps -aq 2>/dev/null || true)
          echo "================ CLEANING VOLUMES ================"
          docker volume prune -f
          echo "=================== CONTAINERS ==================="
          docker ps -a
      }
      # Project jump function
      pj() {
        local projects=(\$HOME/Projects/*)
        local project=\$(printf "%s\\n" "''${projects[@]}" | fzf --height 40% --reverse)
        if [[ -n "''${project}" ]]; then
          cd "\$project"
        fi
      }
      # Trash management helpers
      trash-clear-all() {
        trash-empty
      }
      trash-restore-last() {
        local last=$(trash-list | tail -n 1 | awk '{print ''$2}')
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
      # pnpm completion
      if type pnpm &>/dev/null; then
        source <(pnpm completion zsh)
      fi
      # turbo completion (disabled to avoid startup warnings)
      # if type turbo &>/dev/null; then
      #   source <(turbo completion zsh &>/dev/null || true)
      # fi
      # nx completion (if installed via npm or globally)
      if type nx &>/dev/null; then
        source <(nx completion zsh || true)
      fi
      # moonrepo: no official zsh completion, see https://moonrepo.dev/docs/guides/shell-completions for updates
      # --- Aider Integration: Function ---
      find_aider_root() {
          # First check if AIDER_ROOT is already set
          if [ -n "$AIDER_ROOT" ] && [ -f "$AIDER_ROOT/pyproject.toml" ]; then
              echo "$AIDER_ROOT"
              return 0
          fi

          # Then check current and parent directories for aider setup
          local current="$PWD"
          local found=""
          while [ "$current" != "/" ]; do
              if [ -f "$current/pyproject.toml" ]; then
                  found="$current"
                  break
              fi
              current="$(dirname "$current")"
          done

          # Fall back to common locations if nothing found in parents
          if [ -z "$found" ]; then
              local locations=(
                  "$HOME/.aider"
              )

              for loc in "''${locations[@]}"; do
                  if [ -d "$loc" ] && [ -f "$loc/pyproject.toml" ]; then
                      found="$loc"
                      break
                  fi
              done
          fi

          if [ -n "$found" ]; then
              echo "$found"
              return 0
          fi

          return 1
      }

      find_aider_config() {
          # Check for config files in order of precedence
          local config_files=(
              "$PWD/.aider/aider.conf.yml"
              "$HOME/.config/aider/aider.conf.yml"
          )

          for config_file in "''${config_files[@]}"; do
              if [ -f "$config_file" ]; then
                  echo "$config_file"
                  return 0
              fi
          done

          return 1
      }

      # --- Aider Integration: Helper Functions ---
      ai() {
        local target_dir="''$(pwd)"
        local aider_root="''$(find_aider_root)"

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please either:"
          echo "1. Run this command from inside an aider project directory"
          echo "2. Set AIDER_ROOT environment variable to point to your aider setup"
          echo "3. Place your aider setup in one of the standard locations"
          return 1
        fi

        poetry -P="''${aider_root}" run aider --model deepseek/deepseek-chat "''${target_dir}" "$@"
      }

      air1() {
        local target_dir="''$(pwd)"
        local aider_root="''$(find_aider_root)"

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please either:"
          echo "1. Run this command from inside an aider project directory"
          echo "2. Set AIDER_ROOT environment variable to point to your aider setup"
          echo "3. Place your aider setup in one of the standard locations"
          return 1
        fi

        poetry -P="''${aider_root}" run aider --model deepseek/deepseek-r1 "''${target_dir}" "$@"
      }
      # Validate required tools
      if ! command -v poetry &>/dev/null; then
        echo "⚠️  Poetry not found - aider integration will not work"
      fi
      if ! command -v yq &>/dev/null; then
        echo "⚠️  yq not found - config file parsing will not work"
      fi

      # --- Aider Integration: Setup ---
      if [ -n "''$(find_aider_root)" ]; then
          export AIDER_ROOT="''$(find_aider_root)"
          # Load environment variables from aider config with proper precedence
          local global_config="$HOME/.aider/config/aider.conf.yml"
          local local_config="$PWD/.aider/aider.conf.yml"

          # Use local config if exists, otherwise global
          local active_config=""
          if [ -f "$local_config" ]; then
              active_config="$local_config"
          elif [ -f "$global_config" ]; then
              active_config="$global_config"
          fi

          if [ -n "$active_config" ]; then
              export DEEPSEEK_API_KEY="''$(yq -r .api_key "''${active_config}" 2>/dev/null || echo "")"
              export AIDER_MODEL="''$(yq -r .model "''${active_config}" 2>/dev/null || echo "deepseek/deepseek-chat")"
          fi

          # Still check for .env in AIDER_ROOT as fallback
          if [ -f "$AIDER_ROOT/.env" ]; then
              export $(grep -v '^#' "$AIDER_ROOT/.env" | xargs)
          fi
      else
          echo "⚠️  Aider setup not found at ~/Projects/Personal/aider-setup"
      fi
      # --- Aider Integration: ai-status function ---
      ai-status() {
        local current_aider_root="''$(find_aider_root)"
        local target_dir="''$(pwd)"
        local config_file="''$(find_aider_config)"

        echo "=== Current Configuration ==="
        echo "Aider Root: ''${AIDER_ROOT:-[not set]}"
        if [ -n "''${DEEPSEEK_API_KEY:-}" ]; then
          echo "API Key: [SET]"
        else
          echo "API Key: [NOT SET]"
        fi
        echo "Default Model: ''${AIDER_MODEL:-deepseek/deepseek-chat}"

        echo "\n=== Directory Analysis ==="
        echo "Current Directory: $target_dir"
        if [ -n "$current_aider_root" ]; then
          echo "Would use Aider Root: $current_aider_root"
          echo -n "Poetry path: "
          poetry -P="$current_aider_root" --version || echo "Could not determine poetry version"

          # Show config file status
          echo "\nConfiguration Files:"
          # Function to print variables in consistent format
          print_vars() {
            local even=1
            while IFS='=' read -r key value; do
              if [ $even -eq 1 ]; then
                printf "\033[38;5;229m%-30s\033[0m\t\033[38;5;229m%s\033[0m\n" "$key" "$value"
                even=0
              else
                printf "\033[38;5;183m%-30s\033[0m\t\033[38;5;183m%s\033[0m\n" "$key" "$value"
                even=1
              fi
            done
          }

          if [ -f "$PWD/.aider/aider.conf.yml" ]; then
              echo "- Local: $PWD/.aider/aider.conf.yml"
              echo "\nLocal Configuration:"
              yq 'del(.aider_ignore) | to_entries | .[] | "\(.key)=\(.value)"' "$PWD/.aider/aider.conf.yml" 2>/dev/null | print_vars || echo "Could not parse local config file"
          else
              echo "- No local config found at $PWD/.aider/aider.conf.yml"
          fi

          if [ -f "$HOME/.aider/config/aider.conf.yml" ]; then
              echo "\n- Global: $HOME/.aider/config/aider.conf.yml"
              echo "\nGlobal Configuration:"
              yq 'del(.aider_ignore) | to_entries | .[] | "\(.key)=\(.value)"' "$HOME/.aider/config/aider.conf.yml" 2>/dev/null | print_vars || echo "Could not parse global config file"
          else
              echo "\n- No global config found at $HOME/.aider/config/aider.conf.yml"
          fi

          # Still check for .env in AIDER_ROOT as fallback
          if [ -f "$current_aider_root/.env" ]; then
            echo "\nEnvironment variables that would be loaded:"
            grep -v '^#' "$current_aider_root/.env" | grep -v '^$' | while read -r line; do
              local var_name="''$(echo "$line" | cut -d= -f1)"
              local var_value="''$(echo "$line" | cut -d= -f2-)"
              if [[ "$var_name" == *API_KEY* || "$var_name" == *SECRET* || "$var_name" == *PASSWORD* ]]; then
                if [ -n "$var_value" ]; then
                  echo "$var_name=[SET]"
                else
                  echo "$var_name=[NOT SET]"
                fi
              else
                echo "$line"
              fi
            done | print_vars
          fi

          # Show version info if available
          echo "\n=== Version Information ==="
          (cd "$current_aider_root" && poetry run aider --version 2>/dev/null || echo "Could not get aider version")
        else
          echo "No valid aider setup found for current directory!"
          echo "Searched in:"
          echo "- Current directory and parents"
          echo "- $HOME/.aider"
        fi
      }
      # (You can add the rest of your custom code here)
    '';
  };
  # Enable fzf globally with zsh integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  # Ensure required tools are installed for completions
  home.packages = with pkgs; [
    fzf
    pnpm
    nodejs
    docker
    turbo
    zsh-powerlevel10k
    asdf
    trash-cli
    just
    yq-go
    getent
    which
    coreutils
    env
    yarn
    poetry
    spicetify-cli
    linuxbrew
    gnused
    gawk
    findutils
    gnugrep
    home-manager
    # Pop!_OS specific paths
    pop-launcher
    pop-shell
    # User-local binaries
    (writeShellScriptBin "pj" (builtins.readFile ./scripts/pj.sh))
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
  # Powerlevel10k: show exit status of last command in prompt (if not already configured)
  # If you want a custom symbol, add to your ~/.p10k.zsh:
  # typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status ...)
}
