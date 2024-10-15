#!/bin/zsh

wiki_script_path="$HOME/.local/bin/render-wiki.sh"
sed -i -e "s#solarized-light#solarized-dark#g" $wiki_script_path
sed -i -e "s#favicon-light#favicon-dark#g" $wiki_script_path
