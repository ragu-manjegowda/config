## TMUX color issus on Mac,

```
# In tmux.confg change this
set -g default-terminal "tmux-256color"

# to this (screen-256color breaks italics in nvim
set -g default-terminal "xterm-256color"
```
