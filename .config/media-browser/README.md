# Media browser

`media-browser [folder-or-file ...]` opens pqiv's fullscreen mixed photo/video
thumbnail grid. With no argument it starts in `~/Pictures` (or your home folder
if Pictures does not exist). Directories are searched recursively.

Dependencies: `pqiv` (with its FFmpeg backend), `mpv`, and `file`. Arch's pqiv
package includes the video backend.

```sh
media-browser ~/Pictures
media-browser "/path/to/mixed media"
```

Press `z` then `i` or `o` for zoom; these are sequences, not simultaneous chords.

## Gallery and photo preview (pqiv)

| Keys | Thumbnail grid | pqiv preview |
|------|----------------|---------------------|
| `h/j/k/l` | Move selection left/down/up/right | Pan the zoomed image |
| `Ctrl+D` / `Ctrl+U` | Page down/up | Next/previous file |
| `Enter` | Open selection; videos launch mpv | Launch mpv for a video |
| Left click | Open the clicked thumbnail | Drag to pan |
| `zi` / `zo` | Open and zoom selected preview in/out | Zoom in/out |
| `n` / `p` | — | Next/previous file |
| `Escape` / `Tab` | Escape quits | Return to thumbnails |
| `q` | Quit | Quit |
| `f` | Toggle fullscreen | Toggle fullscreen |

Single-click activation uses pqiv's fullscreen mouse bindings. In optional
windowed mode, use Enter or pqiv's normal double-click preview behavior.

## Video playback (mpv)

Activating a video launches fullscreen mpv with audio. Closing mpv reveals
pqiv's preview of the selected video; press `Escape` or `Tab` there to return
to the thumbnail grid.

| Keys | Action |
|------|--------|
| `zi` / `zo` | Zoom in/out |
| `h/j/k/l` | Pan left/down/up/right |
| `Ctrl+D` / `Ctrl+U` | Seek forward/backward 30 seconds |
| `Space` | Pause/resume |
| Left/right arrows | Seek backward/forward 5 seconds |
| `f` | Toggle fullscreen |
| `q` | Close playback and return to pqiv |

The media-browser mpv bindings are loaded from `mpv-input.conf` by the launcher.
pqiv loads `pqivrc` from the same configuration directory.
