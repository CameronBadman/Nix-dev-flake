{
  description = "Tmux configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Tmux configuration file
        tmuxConfig = pkgs.writeTextFile {
          name = "tmux.conf";
          text = ''
            # Tmux configuration file
            
            # Set prefix to Ctrl-a
            unbind C-b
            set -g prefix C-a
            bind C-a send-prefix
            
            # Enable mouse support
            set -g mouse on
            
            # Start window numbering at 1
            set -g base-index 1
            setw -g pane-base-index 1
            
            # Renumber windows when a window is closed
            set -g renumber-windows on
            
            # Increase scrollback buffer size
            set -g history-limit 50000
            
            # Set terminal to use true colors
            set -g default-terminal "tmux-256color"
            set-option -ga terminal-overrides ",xterm-256color:Tc"
            
            # Faster command sequences
            set -sg escape-time 0
            
            # Automatically rename windows based on current program
            setw -g automatic-rename on
            
            # Reload configuration file
            bind r source-file ~/.tmux.conf \; display "Configuration reloaded!"
            
            # Split windows using | and -
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            
            # Vim-like pane navigation
            bind h select-pane -L
            bind j select-pane -D
            bind k select-pane -U
            bind l select-pane -R
            
            # Resizing panes
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5
            
            # Status bar styling (Kanagawa-inspired colors)
            set -g status-style "bg=#1F1F28,fg=#DCD7BA"
            set -g window-status-current-style "bg=#7E9CD8,fg=#1F1F28,bold"
            set -g window-status-style "bg=#2A2A37,fg=#DCD7BA"
            set -g pane-border-style "fg=#2A2A37"
            set -g pane-active-border-style "fg=#7E9CD8"
            set -g status-left "#[fg=#1F1F28,bg=#7E9CD8,bold] #S "
            set -g status-right "#[fg=#DCD7BA,bg=#2A2A37] %Y-%m-%d #[fg=#1F1F28,bg=#7E9CD8,bold] %H:%M "
            set -g status-left-length 20
            set -g status-right-length 40
            set -g status-position top
            
            # Activity monitoring
            setw -g monitor-activity on
            set -g visual-activity off
          '';
          destination = "/tmux.conf";
        };
        
        # Create a shell script to install the config
        installScript = pkgs.writeShellScriptBin "install-tmux-config" ''
          cp ${tmuxConfig}/tmux.conf ~/.tmux.conf
          echo "Tmux configuration installed to ~/.tmux.conf"
        '';
        
      in {
        packages = {
          default = installScript;
          tmuxConfig = tmuxConfig;
        };
        
        # Development shell with tmux available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.tmux
            installScript
          ];
          
          shellHook = ''
            echo "Tmux development shell activated"
            echo "Run 'install-tmux-config' to install the configuration"
          '';
        };
        
        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }: {
          programs.tmux = {
            enable = true;
            shortcut = "a";
            baseIndex = 1;
            escapeTime = 0;
            mouse = true;
            historyLimit = 50000;
            terminal = "tmux-256color";
            keyMode = "vi";
            extraConfig = ''
              # Set terminal to use true colors
              set-option -ga terminal-overrides ",xterm-256color:Tc"
              
              # Split windows using | and -
              bind | split-window -h -c "#{pane_current_path}"
              bind - split-window -v -c "#{pane_current_path}"
              
              # Vim-like pane navigation
              bind h select-pane -L
              bind j select-pane -D
              bind k select-pane -U
              bind l select-pane -R
              
              # Resizing panes
              bind -r H resize-pane -L 5
              bind -r J resize-pane -D 5
              bind -r K resize-pane -U 5
              bind -r L resize-pane -R 5
              
              # Status bar styling (Kanagawa-inspired colors)
              set -g status-style "bg=#1F1F28,fg=#DCD7BA"
              set -g window-status-current-style "bg=#7E9CD8,fg=#1F1F28,bold"
              set -g window-status-style "bg=#2A2A37,fg=#DCD7BA"
              set -g pane-border-style "fg=#2A2A37"
              set -g pane-active-border-style "fg=#7E9CD8"
              set -g status-left "#[fg=#1F1F28,bg=#7E9CD8,bold] #S "
              set -g status-right "#[fg=#DCD7BA,bg=#2A2A37] %Y-%m-%d #[fg=#1F1F28,bg=#7E9CD8,bold] %H:%M "
              set -g status-left-length 20
              set -g status-right-length 40
              set -g status-position top
            '';
          };
        };
      }
    );
}
