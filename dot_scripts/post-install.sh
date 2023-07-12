#!/bin/bash

# Function to check if a command is available
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to ask user for installation confirmation
function confirm_installation() {
  if ! command_exists "$1"; then
    read -p "Do you want to install $1? (y/n): " choice
    case "$choice" in 
        y|Y )
            return 0
            ;;
        * )
            return 1
            ;;
    esac
  else
    echo "detected $1 is already installed."
    return 1
  fi
}


# Install zsh
if confirm_installation "zsh"; then
  echo "Installing zsh..."
  #...
  chsh -s $(which zsh)
  zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh)
fi

# Install tmux
if confirm_installation "tmux"; then
  echo "Installing tmux..."
  #...
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install fzf
if confirm_installation "fzf"; then
  echo "Installing fzf..."
  #...
fi

# Install zoxide
if confirm_installation "zoxide"; then
  echo "Installing zoxide..."
  #...
fi

# Install vim
if confirm_installation "vim"; then
  echo "Installing vim..."
  #...
fi

# Install chezmoi
if confirm_installation "chezmoi"; then
  echo "Installing chezmoi..."
  #...
fi

# Apply dotfiles with chezmoi
echo "Applying dotfiles with chezmoi..."
chezmoi init https://github.com/avnogy/dotfiles
chezmoi apply

echo "Installation completed successfully!"

