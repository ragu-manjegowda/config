# Migrate homebrew


## Backup existing homebrew formulas

```
$ ./backup-homebrew.sh > restore-homebrew_{OS}.sh
$ chmod u+x restore-homebrew_{OS}.sh
```

## Install homebrew on new machine

### Mac OS

Prefer keeping them in custom location (usually ~/Documents)

```
$ mkdir homebrew && \
  curl -L https://github.com/Homebrew/brew/tarball/master | \
  tar xz --strip 1 -C homebrew
```

### Ubuntu

Prefer installing to default location `/home/linuxbrew/.linuxbrew` as bottles does not work for other install locations.

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
	
## Change default shell

```sh
$ chsh -s $(which zsh)
```
