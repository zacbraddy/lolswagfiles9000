{ config, pkgs, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      data = {
        path = "${config.home.homeDirectory}/.config/secrets/data";
        mode = "0600";
      };
    };
  };
}
