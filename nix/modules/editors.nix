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
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-marketplace; [
      dracula-theme.theme-dracula
      zhuangtongfa.material-theme
      ms-python.python
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      ms-azuretools.vscode-docker
      eamodio.gitlens
      ms-vscode-remote.remote-containers
      mhutchie.git-graph
      ms-ossdata.vscode-pgsql
      ms-vscode.vscode-typescript-next
    ];
  };

  # VSCode global settings and extensions management
  home.file.".config/Code/User/settings.json" = {
    text = ''
      {
        // Font and appearance
        "editor.fontFamily": "JetBrains Mono, 'FiraCode Nerd Font', 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "editor.fontLigatures": true,
        "editor.fontSize": 14,
        "workbench.colorTheme": "Dracula",
        // Editor behavior
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "files.autoSave": "onWindowChange",
        "files.trimTrailingWhitespace": true,
        "files.insertFinalNewline": true,
        "editor.minimap.enabled": false,
        // Terminal
        "terminal.integrated.fontFamily": "JetBrains Mono, 'FiraCode Nerd Font', 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "terminal.integrated.fontSize": 13,
        // Misc
        "explorer.confirmDelete": false
      }
    '';
  };

  home.file.".config/Code/User/extensions.json" = {
    text = ''
      {
        "recommendations": [
          "zhuangtongfa.Material-theme", // One Dark Pro
          "dracula-theme.theme-dracula", // Dracula Official Theme
          "ms-python.python",
          "esbenp.prettier-vscode",
          "dbaeumer.vscode-eslint",
          "ms-azuretools.vscode-docker",
          "eamodio.gitlens",
          "ms-vscode-remote.remote-containers",
          "mhutchie.git-graph",
          "ms-ossdata.vscode-postgresql",
          "ms-vscode.vscode-typescript-next"
        ]
      }
    '';
  };

  # Cursor global settings and extensions management (identical to VSCode, but only recommendations)
  home.file.".config/Cursor/User/settings.json".source = ./cursor-settings.json;

  home.file.".config/Cursor/User/extensions.json" = {
    text = ''
      {
        "recommendations": [
          "zhuangtongfa.Material-theme", // One Dark Pro
          "dracula-theme.theme-dracula", // Dracula Official Theme
          "ms-python.python",
          "esbenp.prettier-vscode",
          "dbaeumer.vscode-eslint",
          "ms-azuretools.vscode-docker",
          "eamodio.gitlens",
          "ms-vscode-remote.remote-containers",
          "mhutchie.git-graph",
          "ms-ossdata.vscode-postgresql",
          "ms-vscode.vscode-typescript-next"
        ]
      }
    '';
  };

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

    # Fetch the latest Cursor AppImage download URL from the official API
    LATEST_URL=$(${pkgs.curl}/bin/curl -s 'https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable' | grep -oP '"downloadUrl":"\\K[^"]+')

    if [ -z "$LATEST_URL" ]; then
      echo "Could not find a download URL for Cursor AppImage. Please check https://www.cursor.com/downloads"
      exit 1
    fi

    mkdir -p "$CURSOR_DIR" "$DESKTOP_DIR" "$(dirname $MIMEAPPS)"

    # Download if not present or if newer
    if [ ! -f "$APPIMAGE_PATH" ]; then
      echo "Downloading latest Cursor AppImage..."
      ${pkgs.curl}/bin/curl -L "$LATEST_URL" -o "$APPIMAGE_PATH"
      chmod +x "$APPIMAGE_PATH"
    fi

    # Create/update .desktop file
    cat > "$CURSOR_DESKTOP_PATH" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$APPIMAGE_PATH %U
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
      # Remove any existing line for this mime type in Default Applications
      sed -i "/^$mime=/d" "$MIMEAPPS"
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
  ];
}
