# Dotfiles
This repository contains the configuration files that I use on a daily basis. You are welcome to fork this repository and make your own modifications.
What to Expect

# Requirements
To be able to use these configuration files fully, you will likely want to have the following installed on your system:

- [vim](https://www.vim.org/)
- [zsh](https://zsh.sourceforge.io)
- [fzf](https://github.com/junegunn/fzf) - for tab complete
- [tmux](https://github.com/tmux/tmux)
- [zoxide](https://github.com/ajeetdsouza/zoxide) - for fast navigation

# How to Use

The configuration files in this repository are managed using chezmoi, a tool for managing your dotfiles across multiple machines. Here's a step-by-step guide on how to use chezmoi to apply these dotfiles on a clean machine:

Install chezmoi on your system. You can find the installation instructions on the chezmoi website.
```
sh -c "$(curl -fsLS git.io/chezmoi)"
```
Initialize chezmoi with the source repository.
```
chezmoi init https://github.com/avnogy/dotfiles
```
Apply the configuration files to your system.
```
chezmoi apply
```
With these steps, you should have successfully applied the dotfiles from the repository to your system.

# Invitation to Contribute
This project is open source and contributions are welcome. If you have any questions, issues, or enhancements, feel free to open an issue or submit a pull request. Your contributions will be greatly appreciated.
