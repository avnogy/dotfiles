alias cdcode='cd /mnt/d/code'
alias ..='cd ../'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias up='sudo apt update; sudo apt upgrade; sudo apt-get autoremove -yy; sudo apt-get clean'
alias ealias='vim ~/.bash_aliases'
alias startrdp='sudo /etc/init.d/xrdp start; mstsc.exe /v:localhost:3390'
alias stoprdp=' sudo /etc/init.d/xrdp stop'
alias rbash='source ~/.bashrc'
alias ra='source ~/.bashrc'
alias rdpshow='showrdp'
alias rdpstart='startrdp'
alias rdpstop='stoprdp'
alias showrdp='mstsc.exe /v:localhost:3390'
alias startrdp='sudo /etc/init.d/xrdp start'
alias stoprdp='sudo /etc/init.d/xrdp stop'
alias gitsh="'/mnt/c/Program Files/Git/bin/bash.exe' -i -l"
alias explorer='explorer.exe .'
alias ll="ls -l --time-style=long-iso"
alias lsh="ls -A -I'*'"
alias pyenv="source .venv/bin/activate"
alias httpserv="sudo python3 -m http.server"
alias cmd="cmd.exe"
alias cdusr="cd /mnt/c/Users/avner/"
alias updog="cmd /c \"python -m updog\""
alias shutdown="cmd /c 'wsl --shutdown'"
alias gs="git status"
alias gd="git diff"
alias gds="git diff --staged"
alias gco='git checkout "$(git branch | sed "s/* //" | sed "s/  //" | fzf)"'
alias gb='git branch'
alias todo="todo-txt"
alias telebot='cdcode && cd commitions/telegram-repeater && ssh -i ~/telegram.pem ec2-user@ec2-34-204-91-110.compute-1.amazonaws.com'
alias scv='cbonsai -liSt 0.01 -w 0.5'
alias cmdo='cmd.exe /c'
#alias nvim="VIMRUNTIME=$HOME/neovim/runtime $HOME/neovim/build/bin/nvim"
