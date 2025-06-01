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
    # syntaxHighlighting intentionally skipped per user selection
    # syntaxHighlighting.enable = true;
    # pnpm, turbo, nx, moonrepo completions and powerlevel10k theme sourcing
    initContent = ''
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
  ];
  home.file.".p10k.zsh".source = ../../zsh/.p10k.zsh;
}
