
# References for keybindings in Alacritty

## Command to display keycode

```sh
showkey -a
```

## Some example keycodes

1. [Alacritty issue #7342](https://github.com/alacritty/alacritty/issues/7342#issuecomment-1892611131)
2. [StackOverflow answer](https://stackoverflow.com/a/75030219)
3. [Tmux wiki](https://github.com/tmux/tmux/wiki/Modifier-Keys#limitations-of-ctrl-keys)


## Example keybindings for Ctrl+`

```toml
[keyboard]
bindings = [
    { chars = "\u0000", key = "`", mods = "Control" },
]
```
