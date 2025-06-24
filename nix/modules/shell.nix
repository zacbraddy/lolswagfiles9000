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
      export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.poetry/bin:$PATH"
      export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
      export PATH="$PATH:$HOME/.spicetify"
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
          docker rm -f $(docker ps -aq)
          echo "================ CLEANING VOLUMES ================"
          docker volume prune -f
          echo "=================== CONTAINERS ==================="
          docker ps -a
      }
      # Project jump function
      pj() {
        local projects=(~/Projects/*)
        local project=$(printf "%s\n" $projects | fzf)
        if [[ -n "$project" ]]; then
          cd "$project"
        fi
      }
      # Trash management helpers
      trash-clear-all() {
        trash-empty
      }
      trash-restore-last() {
        local last=$(trash-list | tail -n 1 | awk '{print $2}')
        if [[ -n "$last" ]]; then
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
        if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
          echo "Unlinking regular ~/.zshrc to avoid Home Manager backup clobbering bug."
          rm "$HOME/.zshrc"
        fi
        bash ~/Projects/Personal/lolswagfiles9000/scripts/hmr.sh -b hmbackup
        echo "Run 'reload' or restart your shell to apply changes."
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
          while [ "$current" != "/" ]; do
              if [ -f "$current/pyproject.toml" ]; then
                  echo "$current"
                  return 0
              fi
              current="$(dirname "$current")"
          done

          # Fall back to common locations
          local locations=(
              "$HOME/Projects/Personal/aider-setup"
              "$HOME/aider-setup"
              "$HOME/.aider"
          )

          for loc in "''${locations[@]}"; do
              if [ -d "$loc" ] && [ -f "$loc/pyproject.toml" ]; then
                  echo "$loc"
                  return 0
              fi
          done

          echo "Could not find aider setup (looking for pyproject.toml in):" >&2
          echo "- Current directory and parents" >&2
          echo "- $HOME/Projects/Personal/aider-setup" >&2
          echo "- $HOME/aider-setup" >&2
          echo "- $HOME/.aider" >&2
          return 1
      }

      # --- Aider Integration: Helper Functions ---
      ai() {
        local target_dir="$(pwd)"
        local aider_root="$(find_aider_root)"

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please either:"
          echo "1. Run this command from inside an aider project directory"
          echo "2. Set AIDER_ROOT environment variable to point to your aider setup"
          echo "3. Place your aider setup in one of the standard locations"
          return 1
        fi

        poetry -P="$aider_root" run aider --model deepseek/deepseek-chat "$target_dir" "$@"
      }

      air1() {
        local target_dir="$(pwd)"
        local aider_root="$(find_aider_root)"

        if [ -z "$aider_root" ]; then
          echo "Error: Could not find aider setup."
          echo "Please either:"
          echo "1. Run this command from inside an aider project directory"
          echo "2. Set AIDER_ROOT environment variable to point to your aider setup"
          echo "3. Place your aider setup in one of the standard locations"
          return 1
        fi

        poetry -P="$aider_root" run aider --model deepseek/deepseek-r1 "$target_dir" "$@"
      }
      # --- Aider Integration: Setup ---
      AIDER_ROOT=$(find_aider_root)
      if [ -n "$AIDER_ROOT" ]; then
          export AIDER_ROOT
          # Load environment variables
          if [ -f "$AIDER_ROOT/.env" ]; then
              export $(grep -v '^#' "$AIDER_ROOT/.env" | xargs)
          fi
          # Source aider environment script if it exists
          if [ -f "$AIDER_ROOT/.aider_env.sh" ]; then
              source "$AIDER_ROOT/.aider_env.sh"
          fi
      else
          echo "⚠️  Aider setup not found at ~/Projects/Personal/aider-setup"
      fi
      # --- Aider Integration: aider-status function ---
      aider-status() {
        echo "Aider Root: $AIDER_ROOT"
        if [ -n "$DEEPSEEK_API_KEY" ]; then
          echo "API Key: [SET]"
        else
          echo "API Key: [NOT SET]"
        fi
        echo "Default Model: ''${AIDER_MODEL:-deepseek/deepseek-chat}"
        pushd "$AIDER_ROOT" >/dev/null
        poetry run aider --version
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
