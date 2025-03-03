{
  description = "Bash configuration with simplified prompt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Bash configuration files
        bashrcConfig = pkgs.writeTextFile {
          name = "bashrc";
          text = ''
            # Bash configuration file
            
            # If not running interactively, don't do anything
            [[ $- != *i* ]] && return
            
            # History settings
            HISTCONTROL=ignoreboth
            HISTSIZE=10000
            HISTFILESIZE=20000
            shopt -s histappend
            
            # Update window size after each command
            shopt -s checkwinsize
            
            # Make less more friendly for non-text input files
            [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
            
            # Enable color support
            if [ -x /usr/bin/dircolors ]; then
                test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
                alias ls='ls --color=auto'
                alias grep='grep --color=auto'
                alias fgrep='fgrep --color=auto'
                alias egrep='egrep --color=auto'
            fi
            
            # Some useful aliases
            alias ll='ls -alF'
            alias la='ls -A'
            alias l='ls -CF'
            alias ..='cd ..'
            alias ...='cd ../..'
            
            # Ultra simple but functional colored prompt
            export PS1='\n\[\e[32m\][\!\]\[\e[0m\] \[\e[34m\][\u@\h:\w]\[\e[0m\]$ '
            
            # Enable programmable completion
            if ! shopt -oq posix; then
              if [ -f /usr/share/bash-completion/bash_completion ]; then
                . /usr/share/bash-completion/bash_completion
              elif [ -f /etc/bash_completion ]; then
                . /etc/bash_completion
              fi
            fi
            
            # Add user's bin directory to PATH if it exists
            if [ -d "$HOME/bin" ] ; then
                PATH="$HOME/bin:$PATH"
            fi
            
            if [ -d "$HOME/.local/bin" ] ; then
                PATH="$HOME/.local/bin:$PATH"
            fi
            
            # Set default editor
            export EDITOR=vim
            
            # Use custom dircolors if it exists
            if [ -f "$HOME/.dircolors" ]; then
                eval "$(dircolors -b $HOME/.dircolors)"
            fi
          '';
          destination = "/bashrc";
        };
        
        # Create a shell script to install the config
        installScript = pkgs.writeShellScriptBin "install-bash-config" ''
          cp ${bashrcConfig}/bashrc ~/.bashrc
          echo "Bash configuration installed to ~/.bashrc"
          echo ""
          echo "To test this configuration, run:"
          echo "  bash --rcfile ${bashrcConfig}/bashrc"
          echo ""
          echo "Or to install and load it in the current shell:"
          echo "  cp ${bashrcConfig}/bashrc ~/.bashrc && source ~/.bashrc"
        '';
        
      in {
        packages = {
          default = installScript;
          bashrcConfig = bashrcConfig;
        };
        
        # Development shell with bash available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bash
            pkgs.bashCompletion
            installScript
          ];
          
          shellHook = ''
            echo "Bash development shell activated"
            echo "Run 'install-bash-config' to install the configuration"
            echo ""
            echo "Or run the following to test directly:"
            echo "  bash --rcfile ${bashrcConfig}/bashrc"
          '';
        };
        
        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }: {
          programs.bash = {
            enable = true;
            historyControl = ["ignoredups" "ignorespace"];
            historyFileSize = 20000;
            historySize = 10000;
            
            shellAliases = {
              ll = "ls -alF";
              la = "ls -A";
              l = "ls -CF";
              ".." = "cd ..";
              "..." = "cd ../..";
            };
            
            initExtra = ''
              # Ultra simple prompt with colors
              export PS1='\n\[\e[32m\][\!\]\[\e[0m\] \[\e[34m\][\u@\h:\w]\[\e[0m\]$ '
            '';
          };
        };
      }
    );
}
