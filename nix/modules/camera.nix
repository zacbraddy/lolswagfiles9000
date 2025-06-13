{ config, pkgs, lib, ... }:

{
  # Ensure v4l-utils is installed
  home.packages = with pkgs; [
    v4l-utils
  ];

  # Create the camera fix script
  home.file.".local/bin/camera-fix.sh" = {
    source = ../../scripts/camera-fix.sh;
    executable = true;
  };

  # Create and enable the systemd service
  systemd.user.services.camera-fix = {
    Unit = {
      Description = "Logitech Webcam Settings Fix";
      After = [ "multi-user.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/camera-fix.sh";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };
    Install = {
      WantedBy = [ "multi-user.target" ];
    };
  };
}
