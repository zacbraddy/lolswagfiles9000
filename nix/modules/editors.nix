{ config, pkgs, lib, ... }:

let
  httpie-desktop = pkgs.stdenv.mkDerivation {
    pname = "httpie-desktop";
    version = "2025.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/httpie/desktop/releases/download/v2025.2.0/HTTPie-2025.2.0.AppImage";
      sha256 = "0kv5dna3rinzys9xmxildjv0qmgyavv62q08g5q0hq0vfhay4l58";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/httpie-desktop.AppImage
      chmod +x $out/bin/httpie-desktop.AppImage
      ln -s $out/bin/httpie-desktop.AppImage $out/bin/httpie-desktop
      mkdir -p $out/share/applications
      cat > $out/share/applications/httpie-desktop.desktop <<EOF
      [Desktop Entry]
      Name=HTTPie Desktop
      Exec=$out/bin/httpie-desktop.AppImage
      Icon=httpie
      Type=Application
      Categories=Development;
      EOF
    '';
    meta = with pkgs.lib; {
      description = "HTTPie Desktop AppImage";
      homepage = "https://httpie.io/desktop";
      platforms = platforms.linux;
    };
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # VSCode auto-install extensions (all from VSCode Marketplace for maximum compatibility)

  # Ensure Cursor directory exists and has correct permissions
  home.activation.setupCursorDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CURSOR_SETTINGS_DIR="$HOME/.config/Cursor/User"
    mkdir -p "$CURSOR_SETTINGS_DIR"
    chmod 755 "$CURSOR_SETTINGS_DIR"
  '';

  # Copy global settings to Cursor
  home.activation.copyCursorSettings = lib.hm.dag.entryAfter [ "writeBoundary" "setupCursorDir" ] ''
    GLOBAL_SETTINGS="$HOME/.config/Cursor/User/settings.json"
    if [ -f "$GLOBAL_SETTINGS" ]; then
      # Only copy if source and destination are different
      if ! cmp -s "$GLOBAL_SETTINGS" "$HOME/.config/Cursor/User/settings.json"; then
        cp "$GLOBAL_SETTINGS" "$HOME/.config/Cursor/User/settings.json"
        chmod 644 "$HOME/.config/Cursor/User/settings.json"
      fi
    fi
  '';

  # Manage extensions.json for both VSCode Insiders and Cursor
  home.file.".vscode/extensions.json".source = ../../.vscode/extensions.json;
  home.file.".config/Cursor/User/extensions.json".source = ../../.vscode/extensions.json;

  home.activation.fixCursorPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.config/Cursor" ]; then
      chown -R $USER:$USER "$HOME/.config/Cursor"
      chmod -R u+rwX "$HOME/.config/Cursor"
    fi
  '';

  home.activation.installCursor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    CURSOR_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    APPIMAGE_NAME="cursor.AppImage"
    APPIMAGE_PATH="$CURSOR_DIR/$APPIMAGE_NAME"
    MIMEAPPS="$HOME/.config/mimeapps.list"
    CURSOR_DESKTOP="cursor.desktop"
    CURSOR_DESKTOP_PATH="$DESKTOP_DIR/$CURSOR_DESKTOP"

    mkdir -p "$CURSOR_DIR" "$DESKTOP_DIR" "$(dirname $MIMEAPPS)"

    # Skip download and desktop file creation if AppImage already exists
    if [ -f "$APPIMAGE_PATH" ]; then
      echo "Cursor AppImage already exists at $APPIMAGE_PATH, skipping installation"
      exit 0
    fi

    # Fetch the latest Cursor AppImage download URL from the official API
    LATEST_URL=$(${pkgs.curl}/bin/curl -s 'https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable' | grep -oP '"downloadUrl":"[^"]+' | cut -d'"' -f3 || true)

    if [ -z "$LATEST_URL" ]; then
      echo "Could not find a download URL for Cursor AppImage. Skipping Cursor installation."
      exit 0
    fi

    echo "Downloading latest Cursor AppImage..."
    ${pkgs.curl}/bin/curl -L "$LATEST_URL" -o "$APPIMAGE_PATH"
    chmod +x "$APPIMAGE_PATH"

    # Create/update .desktop file
    cat > "$CURSOR_DESKTOP_PATH" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$APPIMAGE_PATH --no-sandbox %U
Icon=cursor
Type=Application
Categories=Development;IDE;
Terminal=false
EOF

    echo "Cursor AppImage installed to $APPIMAGE_PATH and .desktop file updated."

    # Idempotent MIME association function
    default_section='[Default Applications]'
    add_mime_default() {
      local mime="$1"
      local desktop="$2"
      # Ensure section exists
      grep -qxF "$default_section" "$MIMEAPPS" || echo "$default_section" >> "$MIMEAPPS"
      # Remove any existing line for this mime type in Default Applications (use | as delimiter to avoid issues with /)
      sed -i "\|^$mime=|d" "$MIMEAPPS"
      # Add the correct line
      awk -v mime="$mime" -v desktop="$desktop" -v section="$default_section" '
        BEGIN {added=0}
        {print}
        $0==section && !added {print mime "=" desktop; added=1}
      ' "$MIMEAPPS" > "$MIMEAPPS.tmp" && mv "$MIMEAPPS.tmp" "$MIMEAPPS"
    }

    # List of MIME types to associate with Cursor
    for mime in \
      application/json \
      application/javascript \
      text/x-python \
      text/x-shellscript
      do
        add_mime_default "$mime" "$CURSOR_DESKTOP"
    done
  '';

  home.packages = with pkgs; [
    audacity
    brave
    google-chrome
    guvcview
    slack
    discord
    obs-studio
    postman
    vlc
    bitwarden
    httpie-desktop
    gedit
    gimp
    libreoffice
    file-roller
    obsidian
    ( (vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
      src = (builtins.fetchTarball {
        url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
        sha256 = "1p740lqnlyv4xl8dmv022f3dk7q8ga5vvx3cmamsk3dyp4rhjgrv";
      });
      version = "latest";
      buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];
    }) )
  ];

  # Obsidian dotfile management
  home.file."Projects/Fireflai/Vaults/FireFlai/.obsidian/appearance.json".source = ../../obsidian/appearance.json;
  home.file."Projects/Fireflai/Vaults/FireFlai/.obsidian/community-plugins.json".source = ../../obsidian/community-plugins.json;
  home.file."Projects/Fireflai/Vaults/FireFlai/.obsidian/core-plugins.json".source = ../../obsidian/core-plugins.json;
  home.file."Projects/Fireflai/Vaults/FireFlai/.obsidian/workspace.json".source = ../../obsidian/workspace.json;
  home.file."Projects/Fireflai/Vaults/FireFlai/.obsidian/vimrc".source = ../../obsidian/vimrc;
}
