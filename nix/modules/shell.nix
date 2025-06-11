{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
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
      # For best appearance, use a Nerd Font or Powerline-patched font (e.g., JetBrains Mono, MesloLGS NF)
    };
    enableCompletion = true;
    autosuggestion.enable = true;
    # Enable syntax highlighting
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
      rm = "trash"; # Use trash instead of rm for safety
      hmr = "home-manager switch --flake .#zacbraddy"; # Home Manager Reload
    };
    initContent = ''
      # Auto-remove files from trash older than 6 months (180 days) on shell startup
      trash-empty 180

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

      # Source powerlevel10k theme from Nix store if available
      if [ -d "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k" ]; then
        source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      fi
      # pnpm completion
      if type pnpm &>/dev/null; then
        source <(pnpm completion zsh)
      fi
      # turbo completion (if installed via npm or globally)
      if type turbo &>/dev/null; then
        source <(turbo completion zsh || true)
      fi
      # nx completion (if installed via npm or globally)
      if type nx &>/dev/null; then
        source <(nx completion zsh || true)
      fi
      # moonrepo: no official zsh completion, see https://moonrepo.dev/docs/guides/shell-completions for updates
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
