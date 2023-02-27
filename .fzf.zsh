# Setup fzf
# ---------
if [[ ! "$PATH" == */home/sleeper/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/sleeper/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/sleeper/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/sleeper/.fzf/shell/key-bindings.zsh"
