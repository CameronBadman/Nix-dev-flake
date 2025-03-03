{
  description = "Terminal configuration for kitty and tmux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
    let
      # System types to support
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper to generate an attrset for each supported system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Import nixpkgs for each system
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # NixOS module
      nixosModules.default = { config, pkgs, lib, ... }: {
        imports = [
          ./modules/tmux.nix
          ./modules/kitty.nix
        ];
      };

      # nix-darwin module
      darwinModules.default = { config, pkgs, lib, ... }: {
        imports = [
          ./modules/tmux.nix
          ./modules/kitty.nix
        ];
      };

      # Home Manager module
      homeManagerModules.default = { config, pkgs, lib, ... }: {
        imports = [
          ./home/tmux.nix
          ./home/kitty.nix
        ];
      };

      # Example NixOS configuration
      nixosConfigurations = {
        example = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.youruser = { ... }: {
                imports = [ self.homeManagerModules.default ];
              };
            }
          ];
        };
      };

      # Example nix-darwin configuration
      darwinConfigurations = {
        example = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            self.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.youruser = { ... }: {
                imports = [ self.homeManagerModules.default ];
              };
            }
          ];
        };
      };
    };
}
