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

  # Create and enable the systemd service
  systemd.user.services.camera-fix = {
    Unit = {
      Description = "Logitech Webcam Settings Fix";
      After = [ "graphical.target" ];
      Wants = [ "graphical.target" ];
      # Add a delay to ensure the camera is fully initialized
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/camera-fix.sh";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
      StandardOutput = "journal";
      StandardError = "journal";
      # Add environment variables for debugging
      Environment = [
        "DEBUG=1"
        "V4L2_DEVICE=/dev/video2"
      ];
    };
    Install = {
      WantedBy = [ "graphical.target" ];
    };
  };

  # Enable systemd user service management
  systemd.user.startServices = true;
}
