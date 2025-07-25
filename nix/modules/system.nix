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
    yq-go
    rclone
    # Browsers
    brave
    google-chrome
    firefox
  ];

  home.keyboard = {
    layout = "gb";
  };

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
  home.file.".config/mimeapps.list" = {
    source = ../../mimeapps.list;
    force = true;
  };

  home.activation.linkPulseAndTuxedo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Use system sudo directly with absolute path
    /usr/bin/sudo ln -sf ${toString ../../default.pa} /etc/pulse/default.pa
    /usr/bin/sudo ln -sf ${toString ../../tuxedo_keyboard.conf} /etc/modprobe.d/tuxedo_keyboard.conf
  '';

  # Install Docker via snap
  home.activation.installDockerSnap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/sudo snap install docker
  '';

  # Install Balena Etcher AppImage
  home.activation.installBalenaEtcher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Checking Balena Etcher installation..."
    APPS_DIR="$HOME/Applications"
    DESKTOP_FILE="$HOME/.local/share/applications/balena-etcher.desktop"
    
    # Create Applications directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p "$APPS_DIR"
    $DRY_RUN_CMD mkdir -p "$HOME/.local/share/applications"
    
    # Check if already installed
    if [ ! -f "$APPS_DIR/balenaEtcher.AppImage" ]; then
      echo "Installing Balena Etcher..."
      
      # Use a known stable download URL for now (latest stable version)
      DOWNLOAD_URL="https://github.com/balena-io/etcher/releases/download/v1.19.25/balenaEtcher-1.19.25-x64.AppImage"
      
      echo "Downloading from: $DOWNLOAD_URL"
      if $DRY_RUN_CMD ${pkgs.curl}/bin/curl -L "$DOWNLOAD_URL" -o "$APPS_DIR/balenaEtcher.AppImage"; then
        $DRY_RUN_CMD chmod +x "$APPS_DIR/balenaEtcher.AppImage"
        
        # Create desktop entry
        $DRY_RUN_CMD cat > "$DESKTOP_FILE" << 'DESKTOP_EOF'
[Desktop Entry]
Name=balenaEtcher
Comment=Flash OS images to SD cards & USB drives, safely and easily.
Exec=%h/Applications/balenaEtcher.AppImage %U
Icon=etcher-electron
Terminal=false
Type=Application
Categories=System;Utility;
StartupWMClass=balenaEtcher
MimeType=application/x-raw-disk-image;application/x-iso9660-image;
DESKTOP_EOF
        
        # Update desktop database
        if command -v ${pkgs.desktop-file-utils}/bin/update-desktop-database >/dev/null 2>&1; then
          $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.local/share/applications"
        fi
        
        echo "✅ Balena Etcher installed successfully"
      else
        echo "❌ Failed to download Balena Etcher"
      fi
    else
      echo "✅ Balena Etcher already installed"
    fi
  '';
}
