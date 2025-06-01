{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [ "git" "z" "sudo" ];
      # For best appearance, use a Nerd Font or Powerline-patched font (e.g., JetBrains Mono, MesloLGS NF)
    };
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
