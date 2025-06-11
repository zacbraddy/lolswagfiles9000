{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    gcc
    gnumake
    binutils
    glibc
    pkg-config
    cacert
    containerd
    curl
    file
    fd
    git
    gnupg
    jetbrains-mono
    libpqxx
    pavucontrol
    postgresql
    ripgrep
    virtualbox
    v4l-utils
    gnome-tweaks
    blueman
    jdk
    just
  ];

  # GNOME/dconf tweaks
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false;
    };
    "org/gnome/desktop/input-sources" = {
      sources = [ "('xkb', 'gb')" ];
      current = 0;
    };
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      cursor-theme = "DMZ-White";
      icon-theme = "ubuntu-mono-dark";
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "slack.desktop"
        "spotify.desktop"
        "brave-browser.desktop"
        "org.gnome.Terminal.desktop"
        "org.gnome.Nautilus.desktop"
        "gnome-control-center.desktop"
        "org.gnome.Characters.desktop"
        "postman_postman.desktop"
        "discord_discord.desktop"
        "snap-store_ubuntu-software.desktop"
      ];
    };
  };

  # Symlink for user config file
  home.file.".config/mimeapps.list".source = ../../mimeapps.list;

  # Symlinks for root-owned config files (requires sudo)
  home.activation.linkPulseAndTuxedo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    sudo ln -sf ${toString ../../default.pa} /etc/pulse/default.pa
    sudo ln -sf ${toString ../../tuxedo_keyboard.conf} /etc/modprobe.d/tuxedo_keyboard.conf
  '';
}
