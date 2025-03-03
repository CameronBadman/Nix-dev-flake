{
  description = "Kitty terminal configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Kitty configuration files
        kittyConfig = pkgs.writeTextFile {
          name = "kitty.conf";
          text = ''
            # Kitty terminal configuration
            
            # Font settings
            font_family      JetBrains Mono
            bold_font        auto
            italic_font      auto
            bold_italic_font auto
            font_size 12.0
            
            # Window settings
            remember_window_size  no
            initial_window_width  1000
            initial_window_height 650
            window_padding_width 4
            hide_window_decorations no
            
            # Transparency
            background_opacity 0.9
            dynamic_background_opacity yes
            
            # Cursor settings
            cursor_shape beam
            cursor_beam_thickness 1.5
            cursor_blink_interval 0.5
            cursor_stop_blinking_after 15.0
            cursor_trail_length 3
            
            # Tab settings
            tab_bar_edge top
            tab_bar_style separator
            
            # Kanagawa theme color scheme
            background #1F1F28
            foreground #DCD7BA
            
            # Black
            color0 #090618
            color8 #727169
            
            # Red
            color1 #C34043
            color9 #E82424
            
            # Green
            color2  #76946A
            color10 #98BB6C
            
            # Yellow
            color3  #C0A36E
            color11 #E6C384
            
            # Blue
            color4  #7E9CD8
            color12 #7FB4CA
            
            # Magenta
            color5  #957FB8
            color13 #938AA9
            
            # Cyan
            color6  #6A9589
            color14 #7AA89F
            
            # White
            color7  #C8C093
            color15 #DCD7BA
            
            # Keyboard shortcuts
            map ctrl+shift+c copy_to_clipboard
            map ctrl+shift+v paste_from_clipboard
            map ctrl+shift+enter new_window
            map ctrl+shift+t new_tab
            map ctrl+shift+q close_tab
            map ctrl+shift+right next_tab
            map ctrl+shift+left previous_tab
          '';
          destination = "/kitty.conf";
        };
        
        # Create a shell script to install the config
        installScript = pkgs.writeShellScriptBin "install-kitty-config" ''
          mkdir -p ~/.config/kitty
          cp ${kittyConfig}/kitty.conf ~/.config/kitty/
          echo "Kitty configuration installed to ~/.config/kitty/"
        '';
        
      in {
        packages = {
          default = installScript;
          kittyConfig = kittyConfig;
        };
        
        # Development shell with kitty available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.kitty
            installScript
          ];
          
          shellHook = ''
            echo "Kitty development shell activated"
            echo "Run 'install-kitty-config' to install the configuration"
          '';
        };
        
        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }: {
          programs.kitty = {
            enable = true;
            settings = {
              font_family = "JetBrains Mono";
              font_size = "12.0";
              background = "#1F1F28";
              foreground = "#DCD7BA";
              background_opacity = "0.9";
              cursor_trail_length = "3";
              # Add more settings to match kitty.conf
            };
          };
        };
      }
    );
}
