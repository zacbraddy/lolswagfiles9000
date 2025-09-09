{ config, pkgs, lib, ... }:

let
  # HTTPie Desktop package
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

  home.packages = [
    # Essential tools
    pkgs.jq
    pkgs.curl
    pkgs.desktop-file-utils
    pkgs.gtk3
    pkgs.xdg-utils
    pkgs.systemd
    pkgs.gnome-shell

    # Applications
    pkgs.audacity
    pkgs.brave
    pkgs.google-chrome
    pkgs.guvcview
    pkgs.slack
    pkgs.discord
    pkgs.obs-studio
    pkgs.postman
    pkgs.vlc
    pkgs.bitwarden
    httpie-desktop
    pkgs.gedit
    pkgs.gimp
    pkgs.libreoffice
    pkgs.file-roller
    pkgs.obsidian
    pkgs.dbeaver-bin

    # VS Code Insiders configuration
    ((pkgs.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
      src = (builtins.fetchTarball {
        url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
        sha256 = "06yb47jsb9a99zk5285lmacr19yh0gl8n61pi58rf6a3yf0sghq3";
      });
      version = "latest";
      buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];
    }))
  ];

  # Cursor settings management
  home.file.".config/Cursor/User/extensions.json".source = ../../.vscode/extensions.json;
  home.file.".config/Cursor/User/settings.json".text =
    let
      # Read your existing settings file
      existingSettings = builtins.fromJSON (builtins.readFile ../../.config/Cursor/User/settings.json);

      # Get the actual store path
      zshStorePath = pkgs.zsh;

      # Shell settings that need dynamic Nix paths
      shellSettings = {
        "terminal.integrated.defaultProfile.linux" = "nix-zsh";

        "terminal.integrated.automationProfile.linux" = {
          "path" = "${zshStorePath}/bin/zsh";
          "args" = ["-l"];
          "env" = {
            "SHELL" = "${zshStorePath}/bin/zsh";
          };
        };

        "terminal.integrated.profiles.linux" = {
          "nix-zsh" = {
            "path" = "${zshStorePath}/bin/zsh";
            "args" = ["-l"];
            "env" = {
              "SHELL" = "${zshStorePath}/bin/zsh";
            };
          };
          "system-zsh" = {
            "path" = "/usr/bin/zsh";
            "args" = ["-l"];
          };
        };

        "terminal.integrated.env.linux" = {
          "PYTHONHOME" = "";
          "PYTHONPATH" = "";
        };
      };

      # Merge existing + shell settings
      mergedSettings = existingSettings // shellSettings;
    in
    builtins.toJSON mergedSettings;

}
