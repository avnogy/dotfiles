#!/bin/sh
echo "Installing chezmoi."
sh -c "$(curl -fsLS git.io/chezmoi)"

echo "Initialize chezmoi with the source repository.."
~/bin/chezmoi init https://github.com/avnogy/dotfiles

echo "Backing up dotfiles..."
backup_folder="dotfiles_backup"
mkdir -p "$backup_folder"
dotfiles=".aliasrc .bashrc .fzf.zsh .lscolors .profile .tmux.conf .vimrc .wslrc .zprofile .zshrc"

for file in "${dotfiles[@]}"; do
  if [ -e "$HOME/$file" ]; then
    mv "$HOME/$file" "$backup_folder/"
    echo "Moved $file to $backup_folder/"
  fi
done

scripts_folder=".scripts"
if [ -d "$HOME/$scripts_folder" ]; then
  mv "$HOME/$scripts_folder" "$backup_folder/"
  echo "Moved $scripts_folder and its contents to $backup_folder/"
fi

echo "Applying dotfiles with chezmoi...."
chezmoi apply

echo "Installation completed successfully!"

