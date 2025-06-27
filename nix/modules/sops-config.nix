{ config, pkgs, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    age.sshKeyPaths = []; # Disable SSH key paths to prevent conflicts
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      data = {
        path = "${config.home.homeDirectory}/.config/secrets/data";
        mode = "0600";
      };
    };
  };
}
