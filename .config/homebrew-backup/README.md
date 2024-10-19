# Migrate homebrew


## Backup existing homebrew formulas

```sh
brew bundle dump --force --file Brewfile_{OS}

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
