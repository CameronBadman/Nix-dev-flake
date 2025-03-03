{
  description = "Minimal development environment with bash, kitty, and tmux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home Manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Optional: darwin support if needed
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs:
  let
    # Define supported systems
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    
    # Function to generate a set for each system
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    # Function to import nixpkgs with overlay for each system
    nixpkgsFor = forAllSystems (system: import nixpkgs {
      inherit system;
      config = { 
        allowUnfree = true; 
      };
    });
  in {
    # Provide default packages for each system
    packages = forAllSystems (system: {
      default = nixpkgsFor.${system}.symlinkJoin {
        name = "terminal-environment";
        paths = with nixpkgsFor.${system}; [
          bash
          kitty
          tmux
        ];
      };
    });
    
    # Default apps
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/kitty";
      };
    });

    # Home Manager modules for each system
    homeManagerModules = forAllSystems (system: {
      default = { pkgs, lib, config, ... }: {
        # Explicitly set home directory
        home = {
          username = "cameronbadman";
          homeDirectory = lib.mkDefault "/Users/cameronbadman";
          
          # Minimal set of packages for the focused environment
          packages = with nixpkgsFor.${system}; [
            # Only essential packages for this minimal setup
            bash-completion
          ];
        };
        
        # Bash configuration
        programs.bash = {
          enable = true;
          enableCompletion = true;
          
          shellAliases = {
            ll = "ls -la";
            ".." = "cd ..";
            "..." = "cd ../..";
          };
          
          bashrcExtra = ''
            # Better history handling
            export HISTSIZE=10000
            export HISTFILESIZE=10000
            export HISTCONTROL=ignoreboth:erasedups
            
            # Better prompt
            export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
            
            # Custom functions
            function mkcd() {
              mkdir -p "$1" && cd "$1"
            }
          '';
          
          initExtra = ''
            # Any additional bash initialization
          '';
        };
        
        # Kitty terminal configuration
        programs.kitty = {
          enable = true;
          settings = {
            # Font configuration
            font_family = "JetBrains Mono";
            font_size = 12;
            
            # Terminal appearance
            background_opacity = "0.95";
            window_padding_width = 8;
            
            # Terminal behavior
            scrollback_lines = 10000;
            enable_audio_bell = false;
            
            # Color scheme
            foreground = "#c0c5ce";
            background = "#2b303b";
            cursor = "#c0c5ce";
            
            # Normal colors
            color0 = "#2b303b"; # black
            color1 = "#bf616a"; # red
            color2 = "#a3be8c"; # green
            color3 = "#ebcb8b"; # yellow
            color4 = "#8fa1b3"; # blue
            color5 = "#b48ead"; # magenta
            color6 = "#96b5b4"; # cyan
            color7 = "#c0c5ce"; # white
          };
          
          keybindings = {
            "ctrl+shift+c" = "copy_to_clipboard";
            "ctrl+shift+v" = "paste_from_clipboard";
            "ctrl+shift+t" = "new_tab";
            "ctrl+shift+w" = "close_tab";
          };
        };
        
        # Tmux configuration
        programs.tmux = {
          enable = true;
          mouse = true;
          terminal = "screen-256color";
          historyLimit = 10000;
          
          # Basic tmux configuration
          extraConfig = ''
            # Start windows and panes at 1, not 0
            set -g base-index 1
            setw -g pane-base-index 1
            
            # Use vim keybindings in copy mode
            setw -g mode-keys vi
            
            # Easier split pane commands
            bind | split-window -h
            bind - split-window -v
            
            # Easier reload of tmux config
            bind r source-file ~/.tmux.conf \; display "Reloaded!"
            
            # Status bar design
            set -g status-justify left
            set -g status-style bg=default
            set -g status-fg colour12
            set -g status-interval 2
            
            # Messaging
            set -g message-style fg=black,bg=yellow
            set -g message-command-style fg=blue,bg=black
          '';
          
          plugins = [];
        };
      };
    });
    
    # Optional Darwin support
    darwinConfigurations = forAllSystems (system: 
      darwin.lib.darwinSystem {
        inherit system;
        modules = [
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cameronbadman = self.homeManagerModules.${system}.default;
          }
        ];
      }
    );
  };
}
