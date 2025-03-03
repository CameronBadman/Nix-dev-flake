{
  description = "Minimal development environment with bash, kitty, and tmux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    # Supported systems
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    
    # Helper function to generate systems
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    # Home Manager modules for terminal applications
    homeManagerModules = {
      kitty = import ./modules/kitty.nix;
      tmux = import ./modules/tmux.nix;
    };

    # Optional: Provide packages if needed
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.symlinkJoin {
        name = "terminal-environment";
        paths = with nixpkgs.legacyPackages.${system}; [
          kitty
          tmux
        ];
      };
    });

    # Optional: Apps for running kitty
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${nixpkgs.legacyPackages.${system}.kitty}/bin/kitty";
      };
    });
  };
}
