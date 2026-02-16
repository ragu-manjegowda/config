# Homebrew Packages

<!--toc:start-->
- [Homebrew Packages](#homebrew-packages)
  - [Install Homebrew](#install-homebrew)
    - [macOS](#macos)
    - [Linux (Ubuntu/Debian)](#linux-ubuntudebian)
  - [Install packages](#install-packages)
  - [Check what is missing](#check-what-is-missing)
  - [Adding or removing packages](#adding-or-removing-packages)
  - [Change default shell](#change-default-shell)
<!--toc:end-->

Manually curated `Brewfile` for macOS and Linux. The file uses `OS.mac?` /
`OS.linux?` guards so a single Brewfile works on both platforms. Dependencies
are resolved automatically by Homebrew; only top-level formulae are listed.

## Install Homebrew

### macOS

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Linux (Ubuntu/Debian)

```sh
sudo apt-get install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Install packages

```sh
brew bundle install --file=~/.config/homebrew-backup/Brewfile
```

## Check what is missing

```sh
brew bundle check --file=~/.config/homebrew-backup/Brewfile --verbose
```

## Adding or removing packages

Edit the `Brewfile` directly and commit the change. To add a new formula,
append it to the appropriate section. To remove one, delete the line.

## Change default shell

```sh
chsh -s $(which zsh)
```
