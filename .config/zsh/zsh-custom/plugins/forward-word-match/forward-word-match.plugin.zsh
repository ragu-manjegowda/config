###############################################################################
# zsh forward-word-match like bash's
#
# Reference: https://stackoverflow.com/a/10860628
###############################################################################

emulate -L zsh
setopt extendedglob

autoload match-words-by-style

local curcontext=":zle:$WIDGET" word
local -a matched_words
integer count=${NUMERIC:-1}

if (( count < 0 )); then
    (( NUMERIC = -count ))
    zle ${WIDGET/forward/backward}
    return
fi

while (( count-- )); do

    match-words-by-style

    # For some reason forward-word doesn't work like the other word
    # commands; it skips whitespace only after any matched word
    # characters.

    if [[ -n $matched_words[4] ]]; then
        # just skip the whitespace and the following word
  word=$matched_words[4]$matched_words[5]
    else
        # skip the word but not the trailing whitespace
  word=$matched_words[5]
    fi

    if [[ -n $word ]]; then
  (( CURSOR += ${#word} ))
    else
  return 1
    fi
done

return 0
