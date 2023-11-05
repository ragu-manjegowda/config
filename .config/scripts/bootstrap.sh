#!/bin/bash

###############################################################################
# Install Homebrew
###############################################################################
# Get Distro
if command -v lsb_release &> /dev/null; then
    DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
elif [ -e /etc/os-release ]; then
    DISTRO=$(grep -Po "(?<=^ID=).+" /etc/os-release | sed 's/"//g')
fi


OS="$(uname)"

if [[ "${OS}" == "Linux" ]]; then
    if [[ "${DISTRO}" == "ubuntu" ]]; then
        # install curl and git
        sudo apt update && sudo apt install -y curl git build-essential zsh python3-pip python3-venv
    elif [[ "${DISTRO}" == "arch" ]]; then
        # install curl and git
        sudo pacman -Syyy && sudo pacman -S git curl base-devel
    fi
fi

# Install Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
###############################################################################


###############################################################################
# Setup dotfiles
###############################################################################
cd ~

mv .config .config.bak

mv .profile .profile.bak

mv .ssh .ssh.bak

git clone https://github.com/ragu-manjegowda/config.git config.git

mv config.git/.git .config.git

shopt -s dotglob

mv -i config.git/* .

rmdir config.git

# git submodule foreach git pull --recurse-submodules --rebase

git --git-dir=$HOME/.config.git --work-tree=$HOME config --local core.worktree $HOME
###############################################################################



###############################################################################
# Restore pacman packages
###############################################################################
if [ "$DISTRO" = "arch" ]
then
    # install paru
    cd ~/Downloads/
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si

    # install packages
    cd ~/.config/archiso-backup/
    ./restore-archiso.sh
fi
###############################################################################



###############################################################################
# Restore brew packages
###############################################################################
cd ~/.config/homebrew-backup/

if [[ "${OS}" == "Linux" ]]
then
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
    ./restore-homebrew_linux.sh
elif [[ "${OS}" == "Darwin" ]]
then
    UNAME_MACHINE="$(/usr/bin/uname -m)"

    if [[ "${UNAME_MACHINE}" == "arm64" ]]
    then
        # On ARM macOS, this script installs to /opt/homebrew only
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        # On Intel macOS, this script installs to /usr/local only
        HOMEBREW_PREFIX="/usr/local"
    fi
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
    ./restore-homebrew_mac.sh
fi
###############################################################################


###############################################################################
# Miscellaneous
###############################################################################
cd ~

# Change default shell
chsh -s $(which zsh)

# Install python provider for neovim
python3 -m pip install --user --upgrade pynvim

# Fix tmux color issue  on Mac OS
if [[ "${OS}" == "Darwin" ]]; then
    sed -i -e "s#tmux-256color#xterm-256color#g" ~/.config/tmux/tmux.conf
fi

# Fix gnupg pinentry program path
if [[ "${OS}" == "Darwin" ]]
then
    sed -i '/pinentry-program/d' ~/.config/gnupg/gpg-agent.conf

    UNAME_MACHINE="$(/usr/bin/uname -m)"

    if [[ "${UNAME_MACHINE}" == "arm64" ]]
    then
        # On ARM macOS, this script installs to /opt/homebrew only
        echo "pinentry-program /opt/homebrew/bin/pinentry-curses" >> ~/.config/gnupg/gpg-agent.conf
    else
        # On Intel macOS, this script installs to /usr/local only
        echo "pinentry-program /usr/local/bin/pinentry-curses" >> ~/.config/gnupg/gpg-agent.conf
    fi
fi
###############################################################################
