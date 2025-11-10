#!/bin/bash
current=$(osascript -e "input volume of (get volume settings)")
if [ "$current" -gt 0 ]; then
  osascript -e "set volume input volume 0"
  osascript -e 'display notification "Microphone muted 🔇" with title "Mic Control"'
else
  osascript -e "set volume input volume 100"
  osascript -e 'display notification "Microphone unmuted 🎤" with title "Mic Control"'
fi
