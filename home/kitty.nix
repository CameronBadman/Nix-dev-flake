# home/kitty.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.kitty;
in {
  options.programs.kitty = {
    enable = mkEnableOption "kitty terminal emulator configuration";
    
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
      description = "Theme for kitty. Can be a name of a built-in theme or a path to a theme file.";
    };
    
    opacity = mkOption {
      type = types.float;
      default = 1.0;
      description = "Opacity for the kitty window (0.0 to 1.0).";
    };
    
    keybindings = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = literalExpression ''
        {
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";
        }
      '';
      description = "Keybindings for kitty.";
    };
    
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to kitty.conf.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
    
    xdg.configFile."kitty/kitty.conf".text = ''
      # Font configuration
      font_family ${cfg.font.name}
      font_size ${toString cfg.font.size}
      
      # Window opacity
      background_opacity ${toString cfg.opacity}
      
      # Theme
      ${if (hasPrefix "/" cfg.theme) then ''
        include ${cfg.theme}
      '' else ''
        include themes/${cfg.theme}.conf
      ''}
      
      # Keybindings
      ${concatStringsSep "\n" (mapAttrsToList (key: action: ''
        map ${key} ${action}
      '') cfg.keybindings)}
      
      # Additional configuration
      ${cfg.extraConfig}
    '';
    
    # Create theme directory and add some default themes
    xdg.configFile."kitty/themes/Dracula.conf".text = ''
      # Dracula theme for kitty
      foreground            #f8f8f2
      background            #282a36
      selection_foreground  #ffffff
      selection_background  #44475a
      
      # black
      color0  #21222c
      color8  #6272a4
      
      # red
      color1  #ff5555
      color9  #ff6e6e
      
      # green
      color2  #50fa7b
      color10 #69ff94
      
      # yellow
      color3  #f1fa8c
      color11 #ffffa5
      
      # blue
      color4  #bd93f9
      color12 #d6acff
      
      # magenta
      color5  #ff79c6
      color13 #ff92df
      
      # cyan
      color6  #8be9fd
      color14 #a4ffff
      
      # white
      color7  #f8f8f2
      color15 #ffffff
      
      # Cursor colors
      cursor            #f8f8f2
      cursor_text_color background
      
      # Tab bar colors
      active_tab_foreground   #282a36
      active_tab_background   #f8f8f2
      inactive_tab_foreground #282a36
      inactive_tab_background #6272a4
      
      # Marks
      mark1_foreground #282a36
      mark1_background #ff5555
    '';
    
    xdg.configFile."kitty/themes/Nord.conf".text = ''
      # Nord theme for kitty
      foreground            #D8DEE9
      background            #2E3440
      selection_foreground  #000000
      selection_background  #FFFACD
      
      # black
      color0   #3B4252
      color8   #4C566A
      
      # red
      color1   #BF616A
      color9   #BF616A
      
      # green
      color2   #A3BE8C
      color10  #A3BE8C
      
      # yellow
      color3   #EBCB8B
      color11  #EBCB8B
      
      # blue
      color4  #81A1C1
      color12 #81A1C1
      
      # magenta
      color5   #B48EAD
      color13  #B48EAD
      
      # cyan
      color6   #88C0D0
      color14  #8FBCBB
      
      # white
      color7   #E5E9F0
      color15  #ECEFF4
      
      # Cursor colors
      cursor            #D8DEE9
      cursor_text_color #2E3440
      
      # Tab bar colors
      active_tab_foreground   #2E3440
      active_tab_background   #88C0D0
      inactive_tab_foreground #D8DEE9
      inactive_tab_background #4C566A
    '';
  };
}
