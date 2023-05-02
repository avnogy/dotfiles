# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022


# set PATH so it includes user's private bin if it exists
if [ -d "~/bin" ] ; then
    PATH="~/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "~/.local/bin" ] ; then
    PATH="~/.local/bin:$PATH"
fi

# Set environment variable
if uname -a | grep -qi "microsoft"; then
  export environment="wsl"
  export WINUSERNAME=$(wslvar USERNAME)
else
  export environment="$(uname -s | tr '[:upper:]' '[:lower:]')"
fi

# adding rust environment
[ -f ~/.cargo/env ] && source ~/.cargo/env
# source rc files 
[ -n "$BASH_VERSION" ]  && [ -f "~/.config/bash/.bashrc" ] && source "~/.config/bash/.bashrc"
# [ -n "$ZSH_VERSION" ]  && [ -f ~/.config/zsh/.zshrc ] && source ~/.config/zsh/.zshrc || echo "oh no"

# Disable annoying beep in X server
[ "$environment" != "darwin" ] && pidof X && xset b off && xset b 0 0 0

export EDITOR="vim"


export ZDOTDIR=$HOME/.config/zsh
