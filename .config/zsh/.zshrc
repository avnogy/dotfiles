# using zap for plugin management
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh" || zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh)

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

stty stop undef		# Disable ctrl-s to freeze terminal.

# automatic completion, history management, and parameter expansion in prompts, and disabling annoying beep alerts
setopt autocd brace_ccl cdable_vars complete_in_word glob_dots hist_expire_dups_first hist_ignore_all_dups hist_ignore_dups hist_save_no_dups inc_append_history interactive_comments nomultios nonomatch notify prompt_subst share_history
unsetopt beep hist_beep

# History in cache directory:
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zshhistory"


# Sourcing .aliasrc
[ -f ~/.config/.aliasrc ] && source ~/.config/.aliasrc || echo "Could not find ~/.aliasrc"

# Sourcing LS_COLORS
[ -f ~/.config/.lscolors ] && source ~/.config/.lscolors || echo "Could not find ls_colors file."

# Sourcing FZF config
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh || echo "Could not find fzf."


# plugins
plug "zsh-users/zsh-autosuggestions"
plug "hlissner/zsh-autopair"
plug "zsh-users/zsh-syntax-highlighting"

# keybinds
bindkey '^ ' autosuggest-accept

if [[ -z $TMUX ]]; then
    tmux -f  ~/.config/tmux/tmux.conf
fi
