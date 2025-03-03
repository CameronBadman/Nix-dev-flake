{
  description = "Darwin configuration with development environment";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    nvim-flake.url = "github:CameronBadman/Nvim-flake";
    
    # Terminal environment configuration
    terminal-env.url = "github:CameronBadman/Nix-dev-flake";
    
    # Home Manager for user configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, darwin, nvim-flake, terminal-env, home-manager, ... }@inputs:
  let 
    system = "aarch64-darwin";
    
    # Configure nixpkgs with allowUnfree enabled
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    darwinConfigurations."camerons-MacBook-Air" = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        # Basic configuration
        {
          # Set the correct GID for nixbld
          ids.gids.nixbld = 350;
          
          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;
          
          nix = {
            enable = true;
            settings = {
              experimental-features = [ "nix-command" "flakes" ];
            };
          };
          
          # Enable zsh
          programs.zsh.enable = true;
          
          # Include development tools directly
          environment.systemPackages = with pkgs; [
            # Neovim from your flake
            nvim-flake.packages.${system}.default
            
            # Terminal tools - core packages for terminal environment
            terminal-env.packages.${system}.default
            kitty
            tmux
            
            # Additional terminal utilities
            bat
            fzf
            ripgrep
            jq
            
            # Containers
            docker
            docker-compose
            kubectl
            
            # Languages
            python3
            rustup
            go
            nodejs
            dafny
            dotnet-sdk
            
            # IDEs
            vscode
            
            # Git
            git
            gh
          ];
          
          # System defaults
          system.defaults = {
            NSGlobalDomain = {
              AppleKeyboardUIMode = 3;
              InitialKeyRepeat = 10;
              KeyRepeat = 1;
            };
            dock = {
              autohide = true;
              orientation = "bottom";
            };
          };
          
          # Setup system shell environment
          environment.shellInit = ''
            # Set up Neovim configuration if needed
            if [ ! -d $HOME/.config/nvim ]; then
              mkdir -p $HOME/.config/nvim
            fi
            
            # Run terminal environment installation script if needed
            if [ ! -f $HOME/.config/.terminal-env-installed ]; then
              echo "Installing terminal environment configurations..."
              ${terminal-env.packages.${system}.default}/bin/install-all-configs
              touch $HOME/.config/.terminal-env-installed
            fi
          '';
          
          system.stateVersion = 4;
        }
        
        # Home Manager module for user-specific configuration
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.cameronbadman = { config, pkgs, ... }: {
            # Import terminal environment Home Manager module
            imports = [
              terminal-env.homeManagerModules.${system}.default
            ];
            
            # Additional home-manager configurations
            home.stateVersion = "23.11";
          };
        }
      ];
    };
    
    # Default package
    packages.${system}.default = self.darwinConfigurations."camerons-MacBook-Air".system;
  };
}
