local plugin_dir="${0:A:h}"

zstyle ':fzf-tab:*' fzf-command "$plugin_dir/fzf-ueberzug"
zstyle ':fzf-tab:complete:*:*' fzf-preview \
    "$plugin_dir/fzf-preview \${(Q)realpath}"
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'

export LESSOPEN="|$plugin_dir/lessfilter %s"
