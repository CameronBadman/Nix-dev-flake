{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.terminal.kitty;
in {
  options.programs.terminal.kitty = {
    enable = mkEnableOption "kitty terminal emulator";
    
    package = mkOption {
      type = types.package;
      default = pkgs.kitty;
      defaultText = literalExpression "pkgs.kitty";
      description = "The kitty package to use.";
    };
    
    font = {
      name = mkOption {
        type = types.str;
        default = "Fira Code";
        description = "Font name for kitty.";
      };
      
      size = mkOption {
        type = types.int;
        default = 12;
        description = "Font size for kitty.";
      };
    };
    
    theme = mkOption {
      type = types.str;
      default = "Dracula";
      description = "Theme name for kitty.";
    };
    
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to kitty.conf.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common configuration for both NixOS and Darwin
    {
      environment.systemPackages = [ cfg.package ];
    }
    
    # NixOS-specific configuration
    (mkIf pkgs.stdenv.isLinux {
      environment.etc."xdg/kitty/kitty.conf".text = ''
        # Font configuration
        font_family ${cfg.font.name}
        font_size ${toString cfg.font.size}
        
        # Theme
        include themes/${cfg.theme}.conf
        
        # Additional configuration
        ${cfg.extraConfig}
      '';
    })
    
    # Darwin-specific configuration
    (mkIf pkgs.stdenv.isDarwin {
      environment.etc."kitty/kitty.conf".text = ''
        # Font configuration
        font_family ${cfg.font.name}
        font_size ${toString cfg.font.size}
        
        # Theme
        include themes/${cfg.theme}.conf
        
        # Additional configuration
        ${cfg.extraConfig}
      '';
    })
  ]);
}
