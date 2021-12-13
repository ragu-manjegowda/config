# Setup fzf
# ---------
if [[ ! "$PATH" == */home/linuxbrew/.linuxbrew/Cellar/fzf/0.28.0/bin* ]]; then
    export PATH="${PATH:+${PATH}:}$(brew --prefix)/Cellar/fzf/0.28.0/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$(brew --prefix)/Cellar/fzf/0.28.0/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "$(brew --prefix)/Cellar/fzf/0.28.0/shell/key-bindings.zsh"
