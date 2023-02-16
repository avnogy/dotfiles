#!/bin/sh

# Setup fzf
# ---------
if [[ ! "$PATH" == */home/linux/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/linux/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/linux/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/linux/.fzf/shell/key-bindings.zsh"
