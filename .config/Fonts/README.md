
# Installation manual of fonts used by configurations

## Mac
    $ brew tap homebrew/cask-fonts
    $ brew install --cask font-hack-nerd-font

## Ubuntu
    $ gcl https://github.com/ryanoasis/nerd-fonts
    $ cd nerd-fonts && ./install Hack
    $ fc-list | grep "Nerd "

## Arch
    $ paru -S ttf-hack-nerd

Note:

Might have to log out and in for fonts to work / get picked up by the system.

On Ubuntu some of the default applications like imagemagick have very little
font size in the menu. Refer - https://legacy.imagemagick.org/discourse-server~/viewtopiccfcd.html?p=149548

```
Unfortunately it seems that display accepts only the so-called X fonts
(ttf fonts do not appear to be available). The list of available X fonts can
be obtained with the `xlsfonts` command. Then the only thing one can hope is to
find a font that is large enough, at least bigger than the default font.
```

One example is - `display -font "rk24"`

