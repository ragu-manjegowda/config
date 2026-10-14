## Popup colors

tmux 3.8 introduced built-in theme colors for popups. Explicit `popup-style`
and `popup-border-style` foreground/background defaults let popups inherit
terminal colors, including Ctrl-R history search through `fzf-tmux`.
The Solarized dark/light terminal theme remains the source of these defaults.

## TMUX color issus on Mac,

```
# In tmux.confg change this
set -g default-terminal "tmux-256color"

# to this (screen-256color breaks italics in nvim)
set -g default-terminal "xterm-256color"
```
