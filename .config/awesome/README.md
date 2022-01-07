
# Awesome Window Manager

Customized this awesome surreal theme to fit my needs (also fixed few things) -
https://github.com/manilarome/the-glorious-dotfiles

Installation process is pretty much covered in the wiki of this repo, following are the detailed steps including various issues and their fix.

### 1. Install awesome from git - follow README from repo
* naughty connect signal will not work with apt-get awesome (v4.3), build and install awesome from git.
* $ git clone https://github.com/awesomeWM/awesome.git
* uncomment `deb-src` lines  from `/etc/apt/sources.list`
* $ sudo apt build-dep awesome
* **Following error were encountered on dirty (actively used for a while) Ubuntu 18.04, installation was smooth on fresh (brand new installation) Ubuntu 20.04.**
    * If there is unment dependency error, fix it (downgrade the packages) with
    $ sudo aptitude -f install packagename
    * instead of `make package` try building first
    * $ mkdir build && cmake ..
    * Fix the errors here using `aptitude -f install`
    * $ make
    * Here LGI was missing, fixed it by installing `lua-lgi`
* $ cd .. && make package
* $ sudo dpkg -i build/awesome*.deb

### 2. Rofi
* $ sudo apt-get install rofi

### 3. Install picom from git - follow README from repo
* $ git clone https://github.com/yshui/picom.git
* $ sudo apt-get update && sudo apt-get install libxext-dev libxcb1-dev
    libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev
    libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev
    libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev
    libxcb-xinerama0-dev libxcb-glx0-dev libpixman-1-dev libdbus-1-dev
    libconfig-dev libgl1-mesa-dev libpcre2-dev libpcre3-dev libevdev-dev
    uthash-dev libev-dev libx11-xcb-dev meson
* $ git submodule update --init --recursive
* $ LDFLAGS="-L/usr/local/lib" CPPFLAGS="-I/usr/local/include" meson --buildtype=release . build
* $ ninja -C build install

### 4. Other dependencies - most of the them are striaght from apt
* $ sudo apt-get install light
* For Ubuntu 20.04 - `$ sudo apt-get install light`
* For Ubuntu 18.04 follow - https://github.com/haikarainen/light and `install pre-built binaries` from release
* $ sudo apt-get update && sudo apt-get install alsa-utils pulseaudio acpi
    acpid mpd mpc maim feh xclip xprop imagemagick blueman redshift
    xfce4-power-manager upower xdg-user-dirs iproute2 iw ffmpeg

### 5. Install lua-pam for lock screen - follow README from repo
* Library compiled for Ubuntu is included in **MY** repo already.
    If it doesn't work, follow the instructions below.
* [Read wiki](https://github.com/manilarome/the-glorious-dotfiles/wiki#how-tos) from the-glorious-dotfiles and then
* $ git clone https://github.com/RMTT/lua-pam.git
* On Ubuntu, need dependency
    $ sudo apt-get install libpam0g-dev
* Cmakelist needs to be modified as it needs `lua5.3` or less for awesome so modify Cmakelist
    * Ubuntu 20.04
        ```
        include_directories(
            /usr/include/lua5.3
        )
        ```
    * Ubuntu 18.04
        ```
        include_directories(
            /home/linuxbrew/.linuxbrew/opt/lua@5.3/include/lua5.3
        )

        link_directories(
            /home/linuxbrew/.linuxbrew/opt/lua@5.3/lib
        )

        add_library(lua_pam SHARED ${SOURCE_DIR}/main.cpp)
        target_link_libraries(lua_pam lua.so.5.3.6 pam)
        ```

### 6. Install xidlehook
 * curl -L https://nixos.org/nix/install | sh
 * nix-env -iA nixos.xidlehook

### 7. Other misc apps
 *  Install `ranger` as it is used as file browser.
 * Install `w3m-img` for image preview in terminal.

### 8. Other configurations
* Wifi connection needs to be updated in configuration/config.lua

## Misc: Various Issues fixed so far (maintaining for my reference as I couldn't push meaningful patched while ricing AWESOME)

1. App drawer rofi error, fixed by removing calc function and by hardcoding px in line 80 of `configuration/rofi/appmenu/rofi.rasi`

2. Network connection status indication bug in `top panel` should be fixed by replacing `config/awesome/surreal/widget/network/init.lua` with the file from https://raw.githubusercontent.com/C0D3-M4513R/the-glorious-dotfiles/257fa51424705665a607bbe68ef1fc361fcc747a/config/awesome/surreal/widget/network/init.lua

3. Screen brightness control (light) has permission issue with Ubuntu 20,
    ```sh
    $ sudo chgrp video /sys/class/backlight/*/brightness
    $ sudo chmod 664 /sys/class/backlight/*/brightness
    $ sudo usermod -a -G video $USER
    ```
    logout and login

4. Changed the fonts everywhere to use Hack Nerd (shipped with **MY** repo!)

5. settings does not open sometimes - use  `dconf reset -f /org/gnome/control-center/`

6. Added apps for wifi control - `nm-applet`

7. Added notification to show when un-muted, same needs to be done for mute.

8. Connect mpc to youtube
    * ``` $ mpc add `youtube-dl -g https://www.youtube.com/watch\?v\=r4mzEgCGa4Q` ```
    * for alsa error -> `$ sudo alsa force-reload`
    * for frontend `ncmpcpp`

9. Configured gpg and sync'd zsh history

10. Added top panel widget for VPN
    * If not required comment out s.vpn in `layout/top-panel.lua`
    * Also modified ui to not showup in task list as it exists in tray when connected by adding rules
    * class name of the application is obtained by `xprop`

11. Added statup command to enable trackpad tapping,
    * `$ xinput set-prop "$touchpad" "libinput Tapping Enabled" 1`
    * touchpad device is obtained by command `xinput list`

12. Enabled natural scrolling through Xorg's settings
    * `$ echo "pointer = 1 2 3 5 4 6 7 8 9 10 11 12" >> ~/.Xmodmap`

13. Added notification for volume mute

14. Changed the low battery notification from 10% to 20%

15. To set tranparency in apps (like alacritty), use `transset` command,
    example `transset 0.9`.

16. Update control-center, info-center and help page width according to
    need,
    .config/awesome/layout/control-center/init.lua:173
    .config/awesome/layout/info-center/init.lua:18
    .config/awesome/configuration/keys/global.lua:8

