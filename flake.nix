{
  description = "Terminal environment configuration for NixOS and MacOS (nix-darwin)";

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
    
    # Add darwin input
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, kitty-config, tmux-config, bash-config, home-manager, darwin, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          inherit system; 
          # Add overlays if needed
          overlays = [];
          # Add needed config for macOS
          config = {
            allowUnfree = true;
            # Add any macOS-specific allowances if needed
          };
        };
        
        # Create a combined install script that sets up all configs
        combinedInstallScript = pkgs.writeShellScriptBin "install-all-configs" ''
          echo "Installing all terminal configurations..."
          
          # Create required directories that might not exist on macOS
          mkdir -p ~/.config
          
          # Install Kitty config
          ${kitty-config.packages.${system}.default}/bin/install-kitty-config
          
          # Install Tmux config
          ${tmux-config.packages.${system}.default}/bin/install-tmux-config
          
          # Install Bash config
          ${bash-config.packages.${system}.default}/bin/install-bash-config
          
          echo "All configurations installed successfully!"
          echo "You may need to restart your terminals for all changes to take effect."
          
          # Provide information based on platform
          if [[ "$OSTYPE" == "darwin"* ]]; then
            echo ""
            echo "On macOS, you may need to manually set Kitty as your default terminal."
            echo "Also ensure your shell is properly configured in Terminal preferences."
          fi
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
    ) // {
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }: {
        imports = [
          home-manager.nixosModules.home-manager
        ];
        
        config = {
          # Add your NixOS specific configurations here if needed
          environment.systemPackages = with pkgs; [
            kitty
            tmux
            bash
          ];
          
          # Configure home-manager as a NixOS module
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${config.users.users.primary.name} = {
            imports = [
              self.homeManagerModules.${pkgs.system}.default
            ];
          };
        };
      };
      
      # Darwin module
      darwinModules.default = { config, lib, pkgs, ... }: {
        imports = [
          home-manager.darwinModules.home-manager
        ];
        
        config = {
          # Add your Darwin specific configurations here
          environment.systemPackages = with pkgs; [
            kitty
            tmux
            bash
          ];
          
          # Install bash properly on macOS
          programs.bash.enable = true;
          
          # Configure home-manager as a Darwin module
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${config.users.primaryUser.name} = {
            imports = [
              self.homeManagerModules.${pkgs.system}.default
            ];
          };
        };
      };
      
      # Standalone home-manager configuration 
      homeManagerConfigurations = 
        let
          supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
          forEachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
        in
        forEachSupportedSystem (system: 
          let
            username = builtins.getEnv "USER";
            homeDirectory = builtins.getEnv "HOME";
            pkgs = import nixpkgs { inherit system; };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              {
                home = {
                  inherit username homeDirectory;
                  stateVersion = "23.11"; # Update to a recent version
                };
              }
              self.homeManagerModules.${system}.default
            ];
          }
        );
    };
}
