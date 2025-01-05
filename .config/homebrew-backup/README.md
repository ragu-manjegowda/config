# Migrate homebrew

<!--toc:start-->
- [Migrate homebrew](#migrate-homebrew)
  - [Backup existing homebrew formulas](#backup-existing-homebrew-formulas)
  - [Install homebrew on new machine](#install-homebrew-on-new-machine)
    - [Mac OS](#mac-os)
    - [Ubuntu](#ubuntu)
  - [Restore homebrew formulas](#restore-homebrew-formulas)
  - [Install Alacritty and Zsh](#install-alacritty-and-zsh)
    - [Mac OS](#mac-os)
    - [Ubuntu](#ubuntu)
  - [Change default shell](#change-default-shell)
<!--toc:end-->


## Backup existing homebrew formulas

```sh
brew bundle dump --force --file Brewfile_{OS}

# Example:
brew bundle dump --file ~/.config/homebrew-backup/Brewfile_linux --force

# Install backup formulas
brew bundle install --file ~/.config/homebrew-backup/Brewfile_linux


# Custom script
./backup-homebrew.sh > restore-homebrew_{OS}.sh
chmod u+x restore-homebrew_{OS}.sh
```

## Install homebrew on new machine

### Mac OS

```sh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Ubuntu

```sh
$ sudo apt-get install build-essential procps curl file git
```

```sh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```sh
$ brew install gcc
```

## Restore homebrew formulas

```sh
brew bundle install --file Brewfile_{OS}
./restore-homebrew_{OS}.sh
```

## Install Alacritty and Zsh

### Mac OS

```sh
$ # zsh comes out of the box
```

```sh
$ brew install alacritty
```

### Ubuntu

```sh
$ sudo apt-get update && sudo apt-get install zsh
```

```sh
$ sudo add-apt-repository ppa:mmstick76/alacritty
```

```sh
$ sudo apt-get update && sudo apt-get install alacritty
```

```sh
$ sudo apt-get update && sudo apt-get install awesome
```

## Change default shell

```sh
$ chsh -s $(which zsh)
```
