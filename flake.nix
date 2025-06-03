{
  description = "Modern, modular dotfiles managed with Nix Flakes and Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Add more inputs as needed (e.g., sops-nix, etc.)
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, nix-vscode-extensions, ... }@inputs: {
    homeConfigurations = {
      zacbraddy = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ nix-vscode-extensions.overlays.default ];
        };
        modules = [
          ./nix/home.nix
          ./nix/modules/shell.nix
          ./nix/modules/editors.nix
          ./nix/modules/languages.nix
          ./nix/modules/devops.nix
          ./nix/modules/system.nix
          ./nix/modules/secrets.nix
        ];
      };
      pop-os = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ nix-vscode-extensions.overlays.default ];
        };
        modules = [
          ./nix/home.nix
          ./nix/modules/shell.nix
          ./nix/modules/editors.nix
          ./nix/modules/languages.nix
          ./nix/modules/devops.nix
          ./nix/modules/system.nix
          ./nix/modules/secrets.nix
        ];
      };
    };
  };
}
