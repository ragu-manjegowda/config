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
        # install enssential packages
        sudo apt update && sudo apt install -y curl git build-essential zsh python3-pip python3-venv
    elif [[ "${DISTRO}" == "arch" ]]; then
        # install curl and git
        sudo pacman -Syyy && sudo pacman -S git curl base-devel
    fi
fi

# Install Homebrew

if command -v brew &> /dev/null; then
    echo "Homebrew already installed"
    echo "To change ownership of brew folder, use the following command:"
    echo "sudo chown -R local-rmanjegowda /raid/ragu/linuxbrew /raid/ragu/linuxbrew/Cellar /raid/ragu/linuxbrew/bin /raid/ragu/linuxbrew/etc /raid/ragu/linuxbrew/etc/bash_completion.d /raid/ragu/linuxbrew/include /raid/ragu/linuxbrew/lib /raid/ragu/linuxbrew/lib/pkgconfig /raid/ragu/linuxbrew/opt /raid/ragu/linuxbrew/sbin /raid/ragu/linuxbrew/share /raid/ragu/linuxbrew/share/aclocal /raid/ragu/linuxbrew/share/doc /raid/ragu/linuxbrew/share/info /raid/ragu/linuxbrew/share/locale /raid/ragu/linuxbrew/share/man /raid/ragu/linuxbrew/share/man/man1 /raid/ragu/linuxbrew/share/man/man3 /raid/ragu/linuxbrew/share/man/man5 /raid/ragu/linuxbrew/share/man/man7 /raid/ragu/linuxbrew/share/man/man8 /raid/ragu/linuxbrew/share/zsh /raid/ragu/linuxbrew/share/zsh/site-functions /raid/ragu/linuxbrew/var/homebrew/linked /raid/ragu/linuxbrew/var/homebrew/locks"
    echo "chmod u+w /raid/ragu/linuxbrew /raid/ragu/linuxbrew/Cellar /raid/ragu/linuxbrew/bin /raid/ragu/linuxbrew/etc /raid/ragu/linuxbrew/etc/bash_completion.d /raid/ragu/linuxbrew/include /raid/ragu/linuxbrew/lib /raid/ragu/linuxbrew/lib/pkgconfig /raid/ragu/linuxbrew/opt /raid/ragu/linuxbrew/sbin /raid/ragu/linuxbrew/share /raid/ragu/linuxbrew/share/aclocal /raid/ragu/linuxbrew/share/doc /raid/ragu/linuxbrew/share/info /raid/ragu/linuxbrew/share/locale /raid/ragu/linuxbrew/share/man /raid/ragu/linuxbrew/share/man/man1 /raid/ragu/linuxbrew/share/man/man3 /raid/ragu/linuxbrew/share/man/man5 /raid/ragu/linuxbrew/share/man/man7 /raid/ragu/linuxbrew/share/man/man8 /raid/ragu/linuxbrew/share/zsh /raid/ragu/linuxbrew/share/zsh/site-functions /raid/ragu/linuxbrew/var/homebrew/linked /raid/ragu/linuxbrew/var/homebrew/locks"

    #######################################################
    ######### to change ownership of brew folder ###########
    # sudo chown -R local-rmanjegowda /raid/ragu/linuxbrew /raid/ragu/linuxbrew/Cellar /raid/ragu/linuxbrew/bin /raid/ragu/linuxbrew/etc /raid/ragu/linuxbrew/etc/bash_completion.d /raid/ragu/linuxbrew/include /raid/ragu/linuxbrew/lib /raid/ragu/linuxbrew/lib/pkgconfig /raid/ragu/linuxbrew/opt /raid/ragu/linuxbrew/sbin /raid/ragu/linuxbrew/share /raid/ragu/linuxbrew/share/aclocal /raid/ragu/linuxbrew/share/doc /raid/ragu/linuxbrew/share/info /raid/ragu/linuxbrew/share/locale /raid/ragu/linuxbrew/share/man /raid/ragu/linuxbrew/share/man/man1 /raid/ragu/linuxbrew/share/man/man3 /raid/ragu/linuxbrew/share/man/man5 /raid/ragu/linuxbrew/share/man/man7 /raid/ragu/linuxbrew/share/man/man8 /raid/ragu/linuxbrew/share/zsh /raid/ragu/linuxbrew/share/zsh/site-functions /raid/ragu/linuxbrew/var/homebrew/linked /raid/ragu/linuxbrew/var/homebrew/locks
    # chmod u+w /raid/ragu/linuxbrew /raid/ragu/linuxbrew/Cellar /raid/ragu/linuxbrew/bin /raid/ragu/linuxbrew/etc /raid/ragu/linuxbrew/etc/bash_completion.d /raid/ragu/linuxbrew/include /raid/ragu/linuxbrew/lib /raid/ragu/linuxbrew/lib/pkgconfig /raid/ragu/linuxbrew/opt /raid/ragu/linuxbrew/sbin /raid/ragu/linuxbrew/share /raid/ragu/linuxbrew/share/aclocal /raid/ragu/linuxbrew/share/doc /raid/ragu/linuxbrew/share/info /raid/ragu/linuxbrew/share/locale /raid/ragu/linuxbrew/share/man /raid/ragu/linuxbrew/share/man/man1 /raid/ragu/linuxbrew/share/man/man3 /raid/ragu/linuxbrew/share/man/man5 /raid/ragu/linuxbrew/share/man/man7 /raid/ragu/linuxbrew/share/man/man8 /raid/ragu/linuxbrew/share/zsh /raid/ragu/linuxbrew/share/zsh/site-functions /raid/ragu/linuxbrew/var/homebrew/linked /raid/ragu/linuxbrew/var/homebrew/locks
    #######################################################

else
    if [ -d "/raid/ragu/linuxbrew" ]; then
        echo "Installing Homebrew to /raid/ragu/linuxbrew"
        HOMEBREW_INSTALL_DIR="/raid/ragu/linuxbrew"
        curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_INSTALL_DIR
    else
        echo "Installing Homebrew to HOME/.linuxbrew"
        HOMEBREW_INSTALL_DIR=""
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    eval "$(${HOMEBREW_INSTALL_DIR}/bin/brew shellenv)"
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"

fi

###############################################################################


###############################################################################
# Setup dotfiles
###############################################################################

cd ~/ || exit

# check if config is already clone
if [ ! -f ~/LICENSE ]; then

    mv .config .config.bak

    mv .profile .profile.bak

    mv .ssh .ssh.bak

    git clone https://github.com/ragu-manjegowda/config.git config.git

    mv config.git/.git .config.git

    shopt -s dotglob

    mv -i config.git/* .

    rmdir config.git

    git --git-dir="${HOME}/.config.git" --work-tree="${HOME}" config --local core.worktree "${HOME}"

    git --git-dir="${HOME}/.config.git" --work-tree="${HOME}" submodule update --init --recursive
fi
###############################################################################



###############################################################################
# Restore pacman packages
###############################################################################
if [ "$DISTRO" = "arch" ]
then
    # install paru
    cd ~/Downloads/ || cd ~/ || exit
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit
    makepkg -si

    # install packages
    cd ~/.config/archiso-backup/ || exit
    ./restore-archiso.sh
fi
###############################################################################



###############################################################################
# Restore brew packages
###############################################################################
cd ~/.config/homebrew-backup/ || exit

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
cd ~/ || exit

# Change default shell
chsh -s "$(which zsh)"

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
