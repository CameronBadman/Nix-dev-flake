{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tmux;
in {
  options.programs.tmux = {
    enable = mkEnableOption "tmux configuration";
    
    baseIndex = mkOption {
      type = types.int;
      default = 1;
      description = "The base index for windows and panes.";
    };
    
    escapeTime = mkOption {
      type = types.int;
      default = 0;
      description = "Time in milliseconds for which tmux waits after an escape is input.";
    };
    
    keyMode = mkOption {
      type = types.enum [ "emacs" "vi" ];
      default = "emacs";
      description = "Key mode for tmux.";
    };
    
    terminal = mkOption {
      type = types.str;
      default = "screen-256color";
      description = "Set the default terminal for new windows.";
    };
    
    shell = mkOption {
      type = types.str;
      default = "";
      description = "Default shell to use in tmux sessions.";
    };
    
    tmuxinator.enable = mkEnableOption "tmuxinator for session management";
    
    plugins = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression "[ pkgs.tmuxPlugins.cpu pkgs.tmuxPlugins.resurrect ]";
      description = "List of tmux plugins to install.";
    };
    
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to tmux.conf.";
    };

    shortcut = mkOption {
      type = types.str;
      default = "b";
      description = "Shortcut key for tmux prefix.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      tmux
    ] ++ (if cfg.tmuxinator.enable then [ tmuxinator ] else [])
      ++ cfg.plugins;
    
    xdg.configFile."tmux/tmux.conf".text = ''
      # Set prefix key
      unbind C-b
      set -g prefix C-${cfg.shortcut}
      bind ${cfg.shortcut} send-prefix

      # Start windows and panes at 1, not 0
      set -g base-index ${toString cfg.baseIndex}
      setw -g pane-base-index ${toString cfg.baseIndex}

      # Reduce escape time
      set -sg escape-time ${toString cfg.escapeTime}

      # Set key mode
      setw -g mode-keys ${cfg.keyMode}

      # Set terminal
      set -g default-terminal "${cfg.terminal}"

      ${optionalString (cfg.shell != "") ''
        # Set default shell
        set -g default-shell "${cfg.shell}"
      ''}

      # Load plugins
      ${concatMapStrings (plugin: ''
        run-shell ${plugin}/share/tmux-plugins/${plugin.pname}
      '') cfg.plugins}

      # Additional configuration
      ${cfg.extraConfig}
    '';
    
    programs.bash.initExtra = mkIf cfg.tmuxinator.enable ''
      # Add tmuxinator completion
      source ${pkgs.tmuxinator}/share/tmuxinator/completion/tmuxinator.bash
    '';
    
    programs.zsh.initExtra = mkIf cfg.tmuxinator.enable ''
      # Add tmuxinator completion
      source ${pkgs.tmuxinator}/share/tmuxinator/completion/tmuxinator.zsh
    '';
  };
}
