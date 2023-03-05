## yadm
My configuration files for Linux, MacOS and WSL2 - managed with [yadm](https://github.com/TheLocehiliosan/yadm)

## Requirements

To be able to use these configuration files fully, you will likely want to have the following installed on your system:

- [fzf](https://github.com/junegunn/fzf)
- [zsh](https://zsh.sourceforge.io)
- [SpaceVim](https://spacevim.org/)
 

## Using My Dotfiles Files

Once you have installed fzf and zsh, you can use these configuration files with a tool like [yadm](https://github.com/TheLocehiliosan/yadm) to manage your dotfiles. 

To install yadm and clone the repository, run the following commands:

```sh
sudo apt install yadm # or your system's equivalent command
yadm clone https://github.com/avnogy/yadm.git
```

**Note:** If you already have dotfiles in your home directory that conflict with the ones in this repository, you may encounter merge conflicts. To avoid this, you can back up and delete the conflicting dotfiles before running the `yadm clone` command.

Alternatively, if you prefer to just clone the repository using normal git, you can use the following command:

```sh
git clone https://github.com/avnogy/yadm.git
```
Once the repository is cloned, you can copy the relevant dotfiles to your home directory manually. For example, to use the .zshrc file, simply copy it to your home directory with the following command:
```sh
cp yadm/.zshrc ~/.zshrc
```
Similarly, you can copy other dotfiles such as .aliasrc, .wslrc, and so on, depending on your needs.



If you have any questions or issues, please feel free to open an issue in the repository or contribute changes back to the project. 
