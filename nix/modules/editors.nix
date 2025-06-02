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
  home.file.".config/Cursor/User/settings.json" = {
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
  ];
}
