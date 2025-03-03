{
  description = "Terminal environment configuration for both NixOS and Darwin";
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
    let
      # Systems that both NixOS and Darwin support
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
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
    ) // {
      # Platform-agnostic outputs
      
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }: {
        imports = [ self.nixosModules.terminal-env ];
      };
      
      # Specific NixOS terminal environment module
      nixosModules.terminal-env = { config, lib, pkgs, ... }: 
      let 
        cfg = config.terminal-environment;
      in {
        options.terminal-environment = with lib; {
          enable = mkEnableOption "Enable terminal environment";
        };
        
        config = lib.mkIf cfg.enable {
          # System packages for the terminal environment
          environment.systemPackages = with pkgs; [
            kitty
            tmux
            bash
            bashCompletion
            
            # Common utilities
            bat
            fzf
            ripgrep
            jq
            neofetch
            htop
            tree
          ];
          
          # Home Manager module for user configuration
          home-manager.sharedModules = [
            ({ system, ... }: 
              # Only import if the system is supported
              if builtins.elem system supportedSystems then
                self.homeManagerModules.${system}.default
              else {}
            )
          ];
        };
      };
      
      # Darwin module
      darwinModules.default = { config, lib, pkgs, ... }: {
        imports = [ self.darwinModules.terminal-env ];
      };
      
      # Specific Darwin terminal environment module
      darwinModules.terminal-env = { config, lib, pkgs, ... }:
      let 
        cfg = config.terminal-environment;
      in {
        options.terminal-environment = with lib; {
          enable = mkEnableOption "Enable terminal environment";
        };
        
        config = lib.mkIf cfg.enable {
          # System packages for the terminal environment
          environment.systemPackages = with pkgs; [
            kitty
            tmux
            bash
            bashCompletion
            
            # Common utilities
            bat
            fzf
            ripgrep
            jq
            neofetch
            htop
            tree
          ];
          
          # Configure tmux directly for Darwin
          programs.tmux.enable = true;
          
          # Home Manager module for user configuration
          home-manager.sharedModules = [
            ({ system, ... }: 
              # Only import if the system is supported
              if builtins.elem system supportedSystems then
                self.homeManagerModules.${system}.default
              else {}
            )
          ];
        };
      };
      
      # Home Manager module (system-agnostic)
      homeManagerModules = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
            default = { ... }: {
              imports = [
                kitty-config.homeManagerModules.${system}.default
                tmux-config.homeManagerModules.${system}.default
                bash-config.homeManagerModules.${system}.default
              ];
            };
          };
        }) supportedSystems
      );
    };
}
