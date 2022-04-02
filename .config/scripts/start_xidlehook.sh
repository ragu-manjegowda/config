#!/usr/bin/env bash

# Run xidlehook
xidlehook \
  `# Don't lock when there's a fullscreen application` \
  --not-when-fullscreen \
  `# Don't lock when there's audio playing` \
  `# --not-when-audio` \
  `# Lock after 120 seconds` \
  --timer 120 \
    'awesome-client \
    "awesome.emit_signal(\"module::lockscreen_show\")" ' \
    '' \
  `# Finally, suspend 300 seconds after it locks` \
  `# --timer 300` \
    `# 'systemctl suspend'` \
    `# ''`
