{ pkgs, lib, config, ... }:
{
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
      color0 = "#2b303b";  # black
      color1 = "#bf616a";  # red
      color2 = "#a3be8c";  # green
      color3 = "#ebcb8b";  # yellow
      color4 = "#8fa1b3";  # blue
      color5 = "#b48ead";  # magenta
      color6 = "#96b5b4";  # cyan
      color7 = "#c0c5ce";  # white
    };
    
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
    };
  };
}
