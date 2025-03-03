{
  description = "Cross-platform terminal configuration files for kitty and tmux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    # Support multiple systems
    supportedSystems = [ 
      "x86_64-linux"   # 64-bit Intel/AMD Linux
      "aarch64-linux"  # ARM Linux
      "x86_64-darwin"  # Intel macOS
      "aarch64-darwin" # Apple Silicon macOS
    ];
    
    # Helper function to generate packages for each system
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    # Package for distributing config files
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.stdenvNoCC.mkDerivation {
        name = "terminal-configs";
        src = self;

        installPhase = ''
          mkdir -p $out
          cp configs/* $out/
        '';

        meta = {
          description = "Cross-platform terminal configuration files";
          homepage = "https://github.com/CameronBadman/Nix-dev-flake";
          license = nixpkgs.lib.licenses.mit;
        };
      };
    });

    # Optional: Modules for easy integration
    nixosModules.default = { config, lib, pkgs, ... }: {
      home-manager.users.${config.users.users.mainUser.name}.home.file = {
        ".config/kitty/kitty.conf".source = 
          "${self.packages.${pkgs.system}.default}/kitty.conf";
        ".config/tmux/tmux.conf".source = 
          "${self.packages.${pkgs.system}.default}/tmux.conf";
      };
    };

    darwinModules.default = { config, lib, pkgs, ... }: {
      home-manager.users.${config.users.users.mainUser.name}.home.file = {
        ".config/kitty/kitty.conf".source = 
          "${self.packages.${pkgs.system}.default}/kitty.conf";
        ".config/tmux/tmux.conf".source = 
          "${self.packages.${pkgs.system}.default}/tmux.conf";
      };
    };
  };
}
