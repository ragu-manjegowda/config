
Followed https://github.com/awesomeWM/awesome.git

Installation is mostly from the wiki, here are the breif steps,

### Install awesome from git - follow README
1. git clone https://github.com/awesomeWM/awesome.git
2. uncomment `deb-src` lines  from `/etc/apt/sources.list`
3. $ sudo apt build-dep awesome

#### Following error were encountered on dirty Ubuntu 18.04, installation was
smooth on fresh Ubuntu 20.04.

4. If there is unment dependency error, fix it (downgrade the packages) with
    $ sudo aptitude -f install packagename
5. instead of `make package` try building first
    $ mkdir build && cmake ..
    Fix the errors here using `aptitude -f install`
    $ make
    Here LGI was missing, fixed it by installing `lua-lgi`
6. $ cd .. && make package
7. $ sudo dpkg -i build/awesome*.deb

### Rofi
1. $ sudo apt-get install rofi

### Install picom from git - follow README
1. $ git clone https://github.com/yshui/picom.git
2. $ sudo apt-get update && sudo apt-get install libxext-dev libxcb1-dev
    libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev
    libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev
    libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev
    libxcb-xinerama0-dev libxcb-glx0-dev libpixman-1-dev libdbus-1-dev
    libconfig-dev libgl1-mesa-dev libpcre2-dev libpcre3-dev libevdev-dev
    uthash-dev libev-dev libx11-xcb-dev meson
3. $ git submodule update --init --recursive
4. $ LDFLAGS="-L/usr/local/lib" CPPFLAGS="-I/usr/local/include" meson --buildtype=release . build
5. $ ninja -C build install


### Other dependencies - striaght from apt (mostly)
1. $ sudo apt-get install light
2. For Ubuntu 20.04
    $ sudo apt-get install light
    For Ubuntu 18.04 follow - https://github.com/haikarainen/light
    install from pre-built binaries from release page
3. $ sudo apt-get update && sudo apt-get install alsa-utils pulseaudio acpi
    acpid mpd mpc maim feh xclip xprop imagemagick blueman redshift
    xfce4-power-manager upower xdg-user-dirs iproute2 iw ffmpeg

### Install lua-pam for lock screen - follow README
1. Library compiled for Ubuntu is included in this repo already.
    If this doesn't work, follow the instructions below.
2. Read wiki from the-glorious-dotfiles and then
3. $ git clone https://github.com/RMTT/lua-pam.git
4. See issues below

### Install misc apps
1. Install `ranger` as it is used as file browser.

## Issues:

1. naughty connect signal will not work with apt-get awesome, build and install
    awesome from git.
    For adding deb packages uncomment deb-src in `/etc/apt/sources.list.d`

2. Install .deb with the command `dpkg -i *.deb`

3. App drawer rofi error, fix by removing calc function and by hardcoding px
    in line 80 of `configuration/rofi/appmenu/rofi.rasi`

4. Wifi connection needs to be updated in configuration/config.lua

5. Connection bug in top panel should be fixed by replacing
`config/awesome/surreal/widget/network/init.lua` with the file from
https://raw.githubusercontent.com/C0D3-M4513R/the-glorious-dotfiles/257fa51424705665a607bbe68ef1fc361fcc747a/config/awesome/surreal/widget/network/init.lua

6. Screen brightness control (light) has permission issue with Ubuntu 20,

```
sudo chgrp video /sys/class/backlight/*/brightness
sudo chmod 664 /sys/class/backlight/*/brightness
sudo usermod -a -G video $USER
```
logout and login

7. Installed couple of fonts needs to be cleaned up

8. Enabled PAM integration for lock screen!
    https://github.com/manilarome/the-glorious-dotfiles/wiki#how-tos

9. settings does not open sometimes - use  `dconf reset -f /org/gnome/control-center/`

10. Added apps for wifi control.

11. Added notification to show when un-muted, same needs to be done for mute.

13. Connect mpc to youtube
mpc add `youtube-dl -g https://www.youtube.com/watch\?v\=r4mzEgCGa4Q`
for alsa error -> `sudo alsa force-reload`
for frontend `ncmpcpp`

14. Configured gpg and sync'd zsh history

15. Added top panel widget for VPN
    If not required comment out s.vpn in `layout/top-panel.lua`
    Also modified ui to not showup in task list as it exists in tray when connected
    by adding rules, class name of the application is obtained by xprop

16. Added statup command to enable trackpad tapping,
    xinput set-prop "$touchpad" "libinput Tapping Enabled" 1
    touchpad device is obtained by command `xinput list`

17. Enabled natural scrolling through Xorg's settings
    `echo "pointer = 1 2 3 5 4 6 7 8 9 10 11 12" >> ~/.Xmodmap`

18. Added notification for volume mute

19. Changed the low battery notification from 10% to 20%

20. PAM integration, follow README.

    * On Ubuntu, need dependency
        $ sudo apt-get install libpam0g-dev

    * Cmakelist needs to be modified
        Need lua 5.3 or less for awesome so modify Cmakelist

    * Ubuntu 20.04,
    include_directories(
        /usr/include/lua5.3
    )


    * Ubuntu 18.04
    include_directories(
        /home/linuxbrew/.linuxbrew/opt/lua@5.3/include/lua5.3
    )

    link_directories(
        /home/linuxbrew/.linuxbrew/opt/lua@5.3/lib
    )

    add_library(lua_pam SHARED ${SOURCE_DIR}/main.cpp)
    target_link_libraries(lua_pam lua.so.5.3.6 pam)

