# Setup fzf
# ---------
# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$(brew --prefix)/opt/fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "$(brew --prefix)/opt/fzf/shell/key-bindings.bash"

