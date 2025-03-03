{
  description = "Minimal development environment with bash, kitty, and tmux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs:
  let
    # Supported systems
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    
    # Helper function to generate systems
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    # Packages for each system
    packagesFor = system: 
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.symlinkJoin {
          name = "terminal-environment";
          paths = with pkgs; [
            bash
            kitty
            tmux
          ];
        };
      };

    # Home Manager module base configuration
    homeManagerModuleBase = { pkgs, lib, config, ... }: {
      home = {
        username = "cameronbadman";
        homeDirectory = 
          if pkgs.stdenv.isDarwin then "/Users/cameronbadman"
          else "/home/cameronbadman";
        stateVersion = "23.11";
        
        packages = with pkgs; [
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
          export HISTSIZE=10000
          export HISTFILESIZE=10000
          export HISTCONTROL=ignoreboth:erasedups
          
          export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
          
          function mkcd() {
            mkdir -p "$1" && cd "$1"
          }
        '';
      };
      
      # Kitty configuration
      programs.kitty = {
        enable = true;
        settings = {
          font_family = "JetBrains Mono";
          font_size = 12;
          background_opacity = "0.95";
          window_padding_width = 8;
          scrollback_lines = 10000;
          enable_audio_bell = false;
          
          foreground = "#c0c5ce";
          background = "#2b303b";
          cursor = "#c0c5ce";
          
          color0 = "#2b303b";
          color1 = "#bf616a";
          color2 = "#a3be8c";
          color3 = "#ebcb8b";
          color4 = "#8fa1b3";
          color5 = "#b48ead";
          color6 = "#96b5b4";
          color7 = "#c0c5ce";
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
        
        extraConfig = ''
          set -g base-index 1
          setw -g pane-base-index 1
          setw -g mode-keys vi
          
          bind | split-window -h
          bind - split-window -v
          
          bind r source-file ~/.tmux.conf \; display "Reloaded!"
          
          set -g status-justify left
          set -g status-style bg=default
          set -g status-fg colour12
          set -g status-interval 2
          
          set -g message-style fg=black,bg=yellow
          set -g message-command-style fg=blue,bg=black
        '';
        
        plugins = [];
      };
    };
  in {
    # Expose packages for all systems
    packages = forAllSystems packagesFor;
    
    # Default apps (run with nix run)
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${
          (nixpkgs.legacyPackages.${system}.callPackage ({ pkgs, writeShellScriptBin }:
            writeShellScriptBin "kitty-with-config" ''
              ${pkgs.kitty}/bin/kitty --config <(${pkgs.home-manager.packages.${system}.home-manager}/bin/home-manager generate-home-config ${toString (homeManagerModuleBase { inherit pkgs; })} | ${pkgs.jq}/bin/jq -r '.programs.kitty.settings | to_entries | map("\(.key) \(.value)") | .[]')
            '') {})}/bin/kitty-with-config";
      };
    });

    # Development shells
    devShells = forAllSystems (system: 
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            git
            vim
          ];
        };
      }
    );
    
    # Darwin Configuration
    darwinConfigurations."camerons-MacBook-Air" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.cameronbadman = homeManagerModuleBase;
          };
        }
      ];
    };
  };
}
