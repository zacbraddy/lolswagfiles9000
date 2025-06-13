{ config, pkgs, ... }:
{
  # Home Manager settings
  home.username = "zacbraddy";
  home.homeDirectory = "/home/zacbraddy";
  home.stateVersion = "24.05"; # Set to the latest stable or your preferred version

  # Import modules
  imports = [
    ./modules/shell.nix
    ./modules/editors.nix
    ./modules/devops.nix
    ./modules/languages.nix
    ./modules/secrets.nix
    ./modules/system.nix
    ./modules/camera.nix
  ];

  # Enable zsh as the default shell
  programs.zsh.enable = true;
  # oh-my-zsh is not a direct option; use programs.zsh.plugins for plugins/themes

  # Essential packages (add more as needed)
  home.packages = with pkgs; [
    git
    sops
    age
    # Add tmux, neovim, or other tools here if needed
  ];

  # Example: basic git config
  programs.git = {
    enable = true;
    userName = "Zac Braddy";
    userEmail = "your-email@example.com";
  };

  # Add more configuration as modules are implemented
}
