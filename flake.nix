{
  description = "Terminal environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Reference the local flakes
    kitty-config = {
      url = "path:./kitty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    tmux-config = {
      url = "path:./tmux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    bash-config = {
      url = "path:./bash";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, kitty-config, tmux-config, bash-config, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Create a combined install script that sets up all configs
        combinedInstallScript = pkgs.writeShellScriptBin "install-all-configs" ''
          echo "Installing all terminal configurations..."
          
          # Install Kitty config
          ${kitty-config.packages.${system}.default}/bin/install-kitty-config
          
          # Install Tmux config
          ${tmux-config.packages.${system}.default}/bin/install-tmux-config
          
          # Install Bash config
          ${bash-config.packages.${system}.default}/bin/install-bash-config
          
          echo "All configurations installed successfully!"
          echo "You may need to restart your terminals for all changes to take effect."
        '';
        
      in {
        packages = {
          default = combinedInstallScript;
          install-script = combinedInstallScript;
        };
        
        # A development shell with all tools available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.kitty
            pkgs.tmux
            pkgs.bash
            pkgs.bashCompletion
            combinedInstallScript
          ];
          
          shellHook = ''
            echo "════════════════════════════════════════════"
            echo "    Terminal Environment Development Shell  "
            echo "════════════════════════════════════════════"
            echo "Available tools:"
            echo "  - kitty: Terminal emulator"
            echo "  - tmux: Terminal multiplexer"
            echo "  - bash: Shell with custom configuration"
            echo ""
            echo "To install all configurations:"
            echo "  install-all-configs"
            echo ""
          '';
        };
        
        # Home Manager module that combines all configurations
        homeManagerModules.default = { config, lib, pkgs, ... }: {
          imports = [
            kitty-config.homeManagerModules.${system}.default
            tmux-config.homeManagerModules.${system}.default
            bash-config.homeManagerModules.${system}.default
          ];
        };
      }
    );
}
