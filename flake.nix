{
  description = "Terminal environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Import the individual config flakes
        kittyConfig = import ./kitty { 
          inherit nixpkgs system pkgs;
        };
        
        tmuxConfig = import ./tmux {
          inherit nixpkgs system pkgs;
        };
        
        bashConfig = import ./bash {
          inherit nixpkgs system pkgs;
        };
        
        # Create a combined install script that sets up all configs
        combinedInstallScript = pkgs.writeShellScriptBin "install-all-configs" ''
          echo "Installing all terminal configurations..."
          
          # Install Kitty config
          mkdir -p ~/.config/kitty
          cp ${kittyConfig.configFile}/kitty.conf ~/.config/kitty/
          echo "✓ Kitty configuration installed to ~/.config/kitty/"
          
          # Install Tmux config
          cp ${tmuxConfig.configFile}/tmux.conf ~/.tmux.conf
          echo "✓ Tmux configuration installed to ~/.tmux.conf"
          
          # Install Bash config
          cp ${bashConfig.configFile}/bashrc ~/.bashrc
          echo "✓ Bash configuration installed to ~/.bashrc"
          
          echo "All configurations installed successfully!"
          echo "You may need to restart your terminals for all changes to take effect."
        '';
        
      in {
        packages = {
          default = combinedInstallScript;
          kitty = kittyConfig.configFile;
          tmux = tmuxConfig.configFile;
          bash = bashConfig.configFile;
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
            kittyConfig.homeManagerModule
            tmuxConfig.homeManagerModule
            bashConfig.homeManagerModule
          ];
          
          # Enable all components by default
          programs = {
            kitty.enable = lib.mkDefault true;
            tmux.enable = lib.mkDefault true;
            bash.enable = lib.mkDefault true;
          };
        };
      }
    );
}
