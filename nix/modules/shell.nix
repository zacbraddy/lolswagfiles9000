{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      gs = "git status";
      ga = "git add .";
      gc = "git commit";
      gp = "git push";
      gd = "git diff";
      gr = "git reset";
      reload = "exec zsh";
      netinfo = "ip a; iwconfig 2>/dev/null; nmcli device status";
      rm = "trash";

    };
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
      ];
    };
    initContent = ''
      # PATH modifications
      export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:''${PATH}"
      export PATH="$HOME/.local/bin:''${PATH}"
      export PATH="$HOME/.poetry/bin:''${PATH}"
      # Linuxbrew paths - only add if they exist
      if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:''${PATH}"
      fi
      export PATH="''${PATH}:$HOME/.spicetify"
      # Bash completion compatibility for pipx and other tools
      autoload -U bashcompinit
      bashcompinit
      # Zsh native completion
      autoload -U compinit compdef && compinit
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
        local projects=(~/Projects/*)
        local project=$(printf "%s\n" $projects | fzf)
        if [[ -n "''${project}" ]]; then
          cd "$project"
        fi
      }
      # Trash management helpers
      trash-clear-all() {
        trash-empty
      }
      trash-restore-last() {
        local last=$(trash-list | tail -n 1 | awk '{print $2}')
        if [[ -n "''${last}" ]]; then
          trash-restore "$last"
        else
          echo "No files in trash to restore." >&2
        fi
      }
      trash-search() {
        if [ -z "$1" ]; then
          echo "Usage: trash-search <pattern>" >&2
          return 1
        fi
        trash-list | grep --color=auto "$1"
      }
      trash-count() {
        trash-list | wc -l | awk '{print $1 " files in trash."}'
      }
      trash-empty-days() {
        if [ -z "$1" ]; then
          echo "Usage: trash-empty-days <days>" >&2
          return 1
        fi
        trash-empty "$1"
      }
      # hmr function for Home Manager repair and reload
      hmr() {
        local log_dir="$HOME/.aider/logs"
        local backup_dir="$HOME/.aider/backups"
        local config_dir="$HOME/.aider/config"
        mkdir -p "$log_dir" "$backup_dir" "$config_dir" \
                 "$HOME/.local/bin" \
                 "$HOME/.local/state/home-manager/gcroots"
        
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local log_file="$log_dir/hmr-$timestamp.log"
        echo "HMR log will be saved to: $log_file"
        
        # Use unbuffered output and append mode to prevent truncation
        exec 3>&1  # Save original stdout
        {
          # Create log sections with clear headers
          log_section() {
            local section="$1"
            echo "===== $(date +'%Y-%m-%d %H:%M:%S') - $section =====" | tee -a "$log_file"
          }

          log_section "HMR STARTED"
          
          # Remove any existing .zshrc (file or symlink)
          log_section "REMOVING EXISTING ZSHRC"
          echo "Removing $HOME/.zshrc..." | tee -a "$log_file"
          rm -f "$HOME/.zshrc" 2>&1 | tee -a "$log_file" || true
          
          # Clear Home Manager's generation backups
          log_section "CLEARING GCROOTS"
          if [ -d "$HOME/.local/state/home-manager/gcroots" ]; then
            echo "Clearing $HOME/.local/state/home-manager/gcroots/*..." | tee -a "$log_file"
            rm -rf "$HOME/.local/state/home-manager/gcroots"/* 2>&1 | tee -a "$log_file" || true
          else
            echo "Directory $HOME/.local/state/home-manager/gcroots does not exist" | tee -a "$log_file"
          fi
          
          # Force a fresh build with verbose output and timestamped backup
          log_section "RUNNING HOME-MANAGER SWITCH"
          local backup_suffix=".backup-$(date +%Y%m%d-%H%M%S)"
          echo "Building fresh Home Manager configuration with backup suffix: $backup_suffix..." | tee -a "$log_file"
          {
            echo "Command: home-manager switch --show-trace --backup --backup-suffix $backup_suffix --backup-dir $backup_dir --extra-experimental-features 'nix-command flakes'"
            home-manager switch --show-trace --backup --backup-suffix "$backup_suffix" --backup-dir "$backup_dir" --extra-experimental-features "nix-command flakes" 2>&1
          } | tee -a "$log_file"
          
          # Clean up old backups (keep last 3)
          echo "Cleaning up old backups..."
          find "$backup_dir" -name '*.backup-*' | sort -r | tail -n +4 | xargs -r rm -f
          
          # Verify the new .zshrc with more detailed debugging
          if [ ! -e "$HOME/.zshrc" ]; then
            echo "❌ Error: Failed to generate new .zshrc!"
            echo "=== Debugging Information ==="
            echo "1. Home Manager executable:"
            which home-manager || echo "Not found in PATH"
            echo "\n2. Nix store path:"
            readlink -f $(which home-manager) || echo "Could not resolve path"
            echo "\n3. Current generation:"
            readlink -f $HOME/.local/state/home-manager/profile || echo "No generation found"
            echo "\n4. Recent generations:"
            ls -la $HOME/.local/state/home-manager/gcroots || echo "Could not list generations"
            echo "\n5. Nix store contents for zshrc:"
            ls -la /nix/store/*-home-manager-files/.zshrc || echo "Could not find .zshrc in store"
            echo "\n6. Home Manager build output:"
            find /nix/store -name "home-manager-generation" -mtime -1 -exec ls -la {} \; || echo "No recent generations found"
            echo "\n7. Environment variables:"
            printenv | grep -E 'NIX|HOME|PATH' || echo "Could not get environment"
            return 1
          elif [ ! -L "$HOME/.zshrc" ]; then
            echo "⚠️ Warning: .zshrc is not a symlink after rebuild!"
            echo "File details:"
            ls -la "$HOME/.zshrc"
            echo "\nFile contents (first 10 lines):"
            head -n 10 "$HOME/.zshrc" || true
          else
            echo "✅ Success: New .zshrc symlink created:"
            ls -la "$HOME/.zshrc"
            echo "\nLinked to:"
            readlink -f "$HOME/.zshrc"
            echo "\nFile contents (first 10 lines):"
            head -n 10 "$(readlink -f "$HOME/.zshrc")" || true
          fi
          
          echo "Run 'reload' or restart your shell to apply changes."
        } | tee -a "$log_file" >&3
        exec 3>&-  # Close fd 3
        
        echo "[$(date +'%H:%M:%S')] Full log saved to:"
        echo "$log_file"
        echo "View it with: cat \"$log_file\""
        
        # Check for errors in the log
        if grep -q "Error:" "$log_file"; then
          echo "Errors detected in HMR process. Last 10 lines:"
          tail -n 10 "$log_file"
          return 1
        fi
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
                  "$HOME/Projects/Personal/aider-setup"
                  "$HOME/aider-setup"
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
          local local_config=""
          if [ -f "$PWD/.aider/aider.conf.yml" ]; then
              local_config="$PWD/.aider/aider.conf.yml"
          fi

          # Use local config if exists, otherwise global
          local active_config="$local_config"
          if [ -z "$active_config" ] && [ -f "$global_config" ]; then
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
          echo "- $HOME/Projects/Personal/aider-setup"
          echo "- $HOME/aider-setup"
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
  ];
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
