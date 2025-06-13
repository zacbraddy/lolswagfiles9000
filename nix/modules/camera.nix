{ config, pkgs, lib, ... }:

{
  # Ensure v4l-utils is installed
  home.packages = with pkgs; [
    v4l-utils
  ];

  # Copy the camera fix script instead of symlinking
  home.activation.installCameraFixScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install -m 755 ${../../scripts/camera-fix.sh} "$HOME/.local/bin/camera-fix.sh"
  '';
}
