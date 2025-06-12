{ config, pkgs, sops-nix, lib, ... }:
{
  imports = [ sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/zacbraddy/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;

    # SSH Keys
    secrets.ssh_private_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };
    secrets.ssh_public_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      mode = "0644";
    };

    # API Tokens
    secrets.github_token = {
      path = "${config.home.homeDirectory}/.config/github/token";
      mode = "0600";
    };
    secrets.aws_credentials = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      mode = "0600";
    };

    # Environment Variables
    secrets.env_file = {
      path = "${config.home.homeDirectory}/.config/env";
      mode = "0600";
    };
  };

  # Create necessary directories
  home.activation = {
    createSecretDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG \
        ${config.home.homeDirectory}/.config/github \
        ${config.home.homeDirectory}/.aws
    '';
  };
}
