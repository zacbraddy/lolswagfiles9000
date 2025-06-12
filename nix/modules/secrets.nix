{ config, pkgs, sops-nix, ... }:
{
  imports = [ sops-nix.homeManagerModules.sops ];
  # Example sops config (to be filled in after key generation)
  # sops = {
  #   age.keyFile = "/home/zacbraddy/.config/sops/age/keys.txt";
  #   defaultSopsFile = ./secrets.yaml;
  #   secrets.example = {};
  # };
}
