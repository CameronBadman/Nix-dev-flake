
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.terminal.tmux;
in {
  options.programs.terminal.tmux = {
    enable = mkEnableOption "tmux terminal multiplexer";
    
    package = mkOption {
      type = types.package;
      default = pkgs.tmux;
      defaultText = literalExpression "pkgs.tmux";
      description = "The tmux package to use.";
    };
    
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to tmux.conf.";
    };
    
    plugins = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression "[ pkgs.tmuxPlugins.cpu pkgs.tmuxPlugins.resurrect ]";
      description = "List of tmux plugins to install.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common configuration for both NixOS and Darwin
    {
      environment.systemPackages = [ cfg.package ] ++ cfg.plugins;
    }
    
    # NixOS-specific configuration
    (mkIf pkgs.stdenv.isLinux {
      environment.etc."tmux.conf".text = ''
        # System-wide tmux configuration
        ${cfg.extraConfig}
      '';
    })
    
    # Darwin-specific configuration
    (mkIf pkgs.stdenv.isDarwin {
      environment.etc."tmux.conf".text = ''
        # System-wide tmux configuration
        ${cfg.extraConfig}
      '';
    })
  ]);
}
