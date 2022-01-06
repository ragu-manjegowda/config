
# wsl-awesome

Dotfiles to run awesomewm inside wsl. 

Initially I had tweaked [this repo](https://github.com/Xyene/wsl-dotfiles), later migrated to Awesome Window Manager
which is use anyways on my machines that run linux natively.


Xyene's has written about running i3 on wsl [here](https://tbrindus.ca/ricing-wsl/).

Also a [script to launch VcXsrv and i3 from Windows](https://github.com/Xyene/wsl-dotfiles/blob/master/wsl.vbs)

**When running with a HiDPI display**, make sure to override `VcXsrv.exe`'s default scaling settings to application-controlled
(Compatibility tab of Properties). Otherwise, Windows will incorrectly scale it, capping your X server to around half the
resolution it should be displaying at (e.g. 1600p instead of 4K).

