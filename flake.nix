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
      inherit system{
  description = "Darwin configuration with development environment";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    nvim-flake.url = "github:CameronBadman/Nvim-flake";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, darwin, nvim-flake, home-manager, ... }@inputs:
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
          
          # Configure tmux directly
          programs.tmux = {
            enable = true;
            shortcut = "a";
            extraConfig = ''
              # Enable mouse mode
              set -g mouse on
              
              # Set 256 color terminal
              set -g default-terminal "screen-256color"
              
              # Start window numbering at 1
              set -g base-index 1
              
              # Reload config with r
              bind r source-file ~/.tmux.conf \; display "Config Reloaded!"
              
              # Split panes using | and -
              bind | split-window -h
              bind - split-window -v
              unbind '"'
              unbind %
              
              # Switch panes using Alt-arrow without prefix
              bind -n M-Left select-pane -L
              bind -n M-Right select-pane -R
              bind -n M-Up select-pane -U
              bind -n M-Down select-pane -D
            '';
          };
          
          # Shell configuration
          environment.shellAliases = {
            ls = "ls --color=auto";
            ll = "ls -la";
            ".." = "cd ..";
            "..." = "cd ../..";
            gs = "git status";
            gl = "git log";
            gp = "git pull";
          };
          
          # Include development tools directly
          environment.systemPackages = with pkgs; [
            # Neovim from your flake
            nvim-flake.packages.${system}.default
            
            # Terminal tools
            kitty
            alacritty
            bat
            fzf
            ripgrep
            jq
            neofetch
            htop
            tree
            
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
            gitAndTools.delta
            diff-so-fancy
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
          '';
          
          system.stateVersion = 4;
        }
        
        # Home Manager module for user-specific configuration
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.cameronbadman = { config, pkgs, ... }: {
            # Kitty configuration
            programs.kitty = {
              enable = true;
              settings = {
                font_family = "JetBrainsMono Nerd Font";
                font_size = 14;
                scrollback_lines = 10000;
                enable_audio_bell = false;
                background_opacity = "0.95";
                window_padding_width = 4;
              };
              theme = "Dracula";
            };
            
            # Bash configuration 
            programs.bash = {
              enable = true;
              shellAliases = {
                ls = "ls --color=auto";
                ll = "ls -la";
                ".." = "cd ..";
                "..." = "cd ../..";
                gs = "git status";
                gl = "git log";
                gp = "git pull";
              };
              bashrcExtra = ''
                # Improved prompt
                export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
                
                # History control
                export HISTCONTROL=ignoreboth
                export HISTSIZE=1000
                export HISTFILESIZE=2000
                
                # Auto-CD
                shopt -s autocd
                
                # Color support
                if [ -x /usr/bin/dircolors ]; then
                    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
                fi
              '';
            };
            
            # Additional home-manager configurations
            home.stateVersion = "23.11";
          };
        }
      ];
    };
    
    # Default package
    packages.${system}.default = self.darwinConfigurations."camerons-MacBook-Air".system;
  };
};
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
