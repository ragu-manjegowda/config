
# wsl-i3

Dotfiles to run i3 inside wsl. I have tweaked it a bit to my needs but most
of the things (>95%) are from [this repo](https://github.com/Xyene/wsl-dotfiles)

Below is the README from Xyene's repo.


# wsl-dotfiles
My dotfiles for running an i3-based environment within WSL, working as of Windows Fall Creators Update (version 1709).

I wrote a bit about this setup [here](https://tbrindus.ca/ricing-wsl/).

Included are configuration files and scripts for:

* i3-gaps
* rofi
* terminator
* polybar
* time-of-day dependent wallpaper switcher
* [script to launch VcXsrv and i3 from Windows](https://github.com/Xyene/wsl-dotfiles/blob/master/wsl.vbs)

**When running with a HiDPI display**, make sure to override `VcXsrv.exe`'s default scaling settings to application-controlled
(Compatibility tab of Properties). Otherwise, Windows will incorrectly scale it, capping your X server to around half the
resolution it should be displaying at (e.g. 1600p instead of 4K).

## Screenshots

![](https://i.imgur.com/ImRRhRZ.jpg)

![](https://i.imgur.com/dn2HI6v.png)

![](https://i.imgur.com/7CB2y1D.jpg)

![](https://i.imgur.com/vVw549M.jpg)

![](https://i.imgur.com/MyKg0fO.jpg)
