{ pkgs, lib, config, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "screen-256color";
    historyLimit = 10000;
    
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
}
