{ config, pkgs, lib, ... }:
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

  # Enable systemd user service management
  systemd.user.startServices = true;

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

  home.activation.addCameraGroup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! /usr/bin/getent group camera-admins; then
      /usr/bin/sudo /usr/sbin/groupadd camera-admins
    fi
    /usr/bin/sudo /usr/sbin/usermod -aG camera-admins $USER
  '';

  home.activation.addUdevRule = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo 'KERNEL=="video[0-9]*", GROUP="camera-admins", MODE="0660"' | /usr/bin/sudo /usr/bin/tee /etc/udev/rules.d/99-camera-admins.rules
    /usr/bin/sudo /usr/bin/udevadm control --reload-rules
    /usr/bin/sudo /usr/bin/udevadm trigger
  '';
}
