
# Awesome Window Manager 
## Setup/Config for Awesome Window Manager on Ubuntu Focal Fossa

[Based on Stup0r38/iceberg-awesome](https://github.com/Stup0r38/iceberg-awesome)

## Associated folders

In addition to `awesome` following files/folders are the complementary setups needed to be copied over to `.config` as well.

- picom.conf
- rofi
- Fonts/Hack Nerd Font

## Tweaks
- Volume control
  - Volume control need to be adapted depending on the output of the `amixer sget Master` command. Need to grep of "Mono" or "Right" in the file `components/volume-adjust.lua`. 

- Screen resolution
  - Get the screen resolution
    ```sh
    $ xdpyinfo | grep -B 2 resolution
    ```

  - Update startup apps in `apps.lua` and `dpi` in `~/.Xresources`

## Installation

- Follow the README from [here](https://github.com/Stup0r38/iceberg-awesome)
- For picom follow [this](https://github.com/ibhagwan/picom)

### Installation commands for Ubuntu Focal Fossa is breifly as follows

```sh
$ sudo apt-get update
```

```sh
$ sudo apt-get install -y awesome feh rofi slock imagemagick acpi xfce4-power-manager bluez blueman ranger
```

```sh
sudo apt-get install -y nm-connection-editor gnome-screenshot alsa-utils xbacklight redshift neofetch zsh 
```

```sh
$ sudo add-apt-repository ppa:mmstick76/alacritty
```

```sh
$ sudo apt-get update
```

```sh
$ sudo apt-get install -y alacritty
```

```sh
$ sudo apt-get install neovim python3-neovim python3-pynvim
```


