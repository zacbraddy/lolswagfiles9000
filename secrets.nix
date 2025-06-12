{ config, pkgs, ... }:
let
  # Replace with your actual age public key
  agePublicKey = "age14k7vy33rt80nctj3kysl79znw8p40rjalja8kvpf7xhg9ed0m35qm74hz7";
in
{
  imports = [
    # Import the sops-nix Home Manager module
    (pkgs.fetchFromGitHub {
      owner = "Mic92";
      repo = "sops-nix";
      rev = "master";
      sha256 = "1q0b58m9bm4kkm19c0d8lbr10cg00ijqn63wqwxfc0s5yv6x1san";
    })
  ];

  sops = {
    age.keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      # Example secret
      exampleSecret = {
        sopsFile = ./secrets.yaml;
        path = "/tmp/example-secret";
      };
    };
  };
}
