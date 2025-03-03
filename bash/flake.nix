{ nixpkgs, system, pkgs }:

let
  # Create the config file
  configFile = pkgs.writeTextFile {
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
      
      # Fancy prompt
      __prompt_command() {
          local EXIT="$?"
          local RCol='\[\e[0m\]'
          local Red='\[\e[1;31m\]'
          local Gre='\[\e[1;32m\]'
          local Blu='\[\e[1;34m\]'
          local Pur='\[\e[1;35m\]'
          local Cya='\[\e[1;36m\]'
          local Yel='\[\e[1;33m\]'
          
          PS1="\n"
          
          if [ $EXIT != 0 ]; then
              PS1+="$Red[\!]$RCol "
          else
              PS1+="$Gre[\!]$RCol "
          fi
          
          PS1+="$Blu[$Yel\u$RCol@$Pur\h$Blu:$Cya\w$Blu]$RCol\\$ "
      }
      
      PROMPT_COMMAND=__prompt_command
      
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
  
  # Define the Home Manager module
  homeManagerModule = { config, lib, pkgs, ... }: {
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
        # Fancy prompt
        __prompt_command() {
            local EXIT="$?"
            local RCol='\[\e[0m\]'
            local Red='\[\e[1;31m\]'
            local Gre='\[\e[1;32m\]'
            local Blu='\[\e[1;34m\]'
            local Pur='\[\e[1;35m\]'
            local Cya='\[\e[1;36m\]'
            local Yel='\[\e[1;33m\]'
            
            PS1="\n"
            
            if [ $EXIT != 0 ]; then
                PS1+="$Red[\!]$RCol "
            else
                PS1+="$Gre[\!]$RCol "
            fi
            
            PS1+="$Blu[$Yel\u$RCol@$Pur\h$Blu:$Cya\w$Blu]$RCol\\$ "
        }
        
        PROMPT_COMMAND=__prompt_command
      '';
    };
  };

in {
  inherit configFile homeManagerModule;
}
