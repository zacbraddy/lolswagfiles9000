{ config, pkgs, lib, ... }:
{
  # Home Manager settings
  home.username = "zacbraddy";
  home.homeDirectory = "/home/zacbraddy";
  home.stateVersion = "24.11"; # Set to the latest stable or your preferred version

  # Import modules
  imports = [
    ./modules/shell.nix
    ./modules/editors.nix
    ./modules/devops.nix
    ./modules/languages.nix
    ./modules/secrets.nix
    ./modules/system.nix
    ./modules/camera.nix
    ./modules/claude.nix
  ];

  # Enable systemd user service management
  systemd.user.startServices = true;

  # Essential packages (add more as needed)
  home.packages = with pkgs; [
    git
    sops
    age
    # Flatpak applications
    flatpak
    # Add neovim or other tools here if needed
  ];

  # Example: basic git config
  programs.git = {
    enable = true;
    userName = "Zac Braddy";
    userEmail = "zacharybraddy@gmail.com";
    aliases = {
      prune-branches = "!git fetch -p && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d";
      prune-branches-force = "!git fetch -p && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D";
      yeet = "!git reset --hard @{u}";
      list-tags = "!git tag -l --format=' %(subject)'";
      edit-unmerged = "!f() { git diff --name-status --diff-filter=U | cut -f2 ; }; /c/vim/vim80/vim.exe `f`";
      add-unmerged = "!f() { git diff --name-status --diff-filter=U | cut -f2 ; }; git add `f`";
    };
    extraConfig = {
      init.defaultBranch = "main";
      fetch.prune = true;
      pull.rebase = true;
      core.editor = "vim";
      core.excludesFile = "~/.gitignore";
      core.autocrlf = "input";
    };
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

  # Install Flatpak applications
  home.activation.installFlatpaks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Enable Flathub repository
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    # Install applications
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub com.adobe.Reader
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub com.bitwarden.desktop
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub com.discordapp.Discord
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub com.obsproject.Studio
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub org.flameshot.Flameshot
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub org.gimp.GIMP
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install -y flathub org.videolan.VLC
  '';
}
