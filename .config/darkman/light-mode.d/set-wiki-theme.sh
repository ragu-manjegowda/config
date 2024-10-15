#!/bin/zsh

wiki_script_path="$HOME/.local/bin/render-wiki.sh"
sed -i -e "s#solarized-dark#solarized-light#g" $wiki_script_path
sed -i -e "s#favicon-dark#favicon-light#g" $wiki_script_path
