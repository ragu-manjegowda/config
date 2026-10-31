# Media browser

`media-browser [folder-or-file ...]` opens pqiv's mixed photo/video
thumbnail grid. With no argument it starts in `~/Pictures` (or your home folder
if Pictures does not exist). Directories are searched recursively.

The gallery and selected photos/videos start as normal tiled windows. Press `f`
in a viewer to toggle fullscreen; in the grid it starts a quick jump instead.

Dependencies: `pqiv` (with its FFmpeg backend), `mpv`, and `file`. Arch's pqiv
package includes the video backend. Trash confirmation additionally uses system
Python, `python-gobject`, and GTK 3. Initial image fitting uses `xdotool` to wait
for the mapped viewer's tile geometry before sending pqiv its native fit action.

```sh
media-browser ~/Pictures
media-browser "/path/to/mixed media"
```

Press `z` then `i` or `o` for zoom; these are sequences, not simultaneous chords.

Enter opens the selected photo in a separate pqiv viewer, or a video in mpv.
The original thumbnail window stays open
with its selection preserved. Closing the viewer does not quit the browser.
Photos are scaled to fit their window while preserving their aspect ratio.
In the photo viewer, `q`, `Escape`, or `Tab` closes only that viewer and reveals
the gallery. Press `q` in the gallery to quit the browser itself.

The gallery and photo viewer use the X11 instances `media-browser-gallery`
and `media-browser-viewer`. Awesome treats both as normal tiled clients,
exempting them from the generic image-viewer always-on-top rule. This lets `f`
toggle fullscreen and lets the focused viewer come forward without the gallery
covering it. Forcing always-on-top also cancels fullscreen in Awesome.

## Gallery and photo preview (pqiv)

| Keys | Thumbnail grid | pqiv preview |
|------|----------------|---------------------|
| `h/j/k/l` | Move selection left/down/up/right | Pan the zoomed image |
| `Ctrl+D` / `Ctrl+U` | Page down/up | Next/previous file |
| `gg` / `G` | First/last image in the whole gallery | — |
| `0` / `$` | First/last thumbnail in the current row | `0` resets image zoom |
| `Enter` | Open selection in a separate normal window | No action |
| `d` | Ask to move the selected file to Trash (`y`/`n`) | — |
| Left click | Select a thumbnail; press Enter to open | Drag to pan |
| `zi` / `zo` | Enlarge/shrink thumbnails without leaving the grid | Zoom image in/out |
| `n` / `p` | — | Next/previous file |
| `Escape` / `Tab` | Escape quits | Close viewer; gallery stays open |
| `q` | Quit | Quit |
| `f` | Show quick-jump labels; type a label to select its thumbnail | Toggle fullscreen |

pqiv only dispatches mouse bindings in fullscreen. In the normal tiled gallery,
click selects a thumbnail and Enter opens it. A single click also opens the
selected item if fullscreen was enabled through the window manager.

Quick-jump labels use the home-row letters `asdfghjkl`. After jumping, Enter
opens the selected item. `G` means Shift+g and now goes to the last image;
`gg` means press g twice.

Thumbnail sizes step through 64, 96, 128, 192, 256 (initial), and 384 pixels.
Repeated `zi`/`zo` stops at the maximum/minimum size. In a photo viewer, the same
keys zoom the image instead.

## Trash

Press `d` on a thumbnail, then `y` to confirm or `n` to cancel. Escape or closing
the confirmation cancels too; the default Enter response is No.

Files go through GIO's Freedesktop Trash implementation, the same desktop trash
specification used by Yazi's normal `remove` command. On the home filesystem
this is normally `$XDG_DATA_HOME/Trash` (default `~/.local/share/Trash`), including
the original-path metadata needed for restoration. Other filesystems can use
their per-volume trash. A trash error is shown rather than falling back to
permanent deletion.

pqiv removes the missing thumbnail automatically. The gallery stays open even
when its last file is trashed; use `q` to quit.

## Video playback (mpv)

Activating a video launches mpv with audio in a normal window. Closing mpv reveals
the original thumbnail grid directly.

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
