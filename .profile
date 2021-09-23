# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  # if running bash
  if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
  	  source "$HOME/.bashrc"
    fi
  # if running zsh
  elif [ -n "$ZSH_VERSION" ]; then
    # include .bash_custom if it exists
    if [ -f "$HOME/.bash_custom" ]; then
      source "$HOME/.bash_custom"
    fi
  fi
  # set PATH so it includes user's private bin directories
  PATH="$HOME/bin:$HOME/.local/bin:$PATH"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # include .bash_profile if it exists
  if [ -f "$HOME/.bash_profile" ]; then
  	source "$HOME/.bash_profile"
  fi
fi

