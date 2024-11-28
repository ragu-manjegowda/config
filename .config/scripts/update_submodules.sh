pushd .

cd ~/.config/awesome/library/battery || exit
git checkout master

cd ~/.config/awesome/library/bling || exit
git checkout master

cd ~/.config/awesome/library/revelation || exit
git checkout master

cd ~/.config/firefox/potatofox || exit
git checkout main

cd ~/.config/fzf-git || exit
git checkout main

cd ~/.config/mpv/scripts/autosubsync || exit
git checkout main

cd ~/.config/rEFInd/refind-theme-regular || exit
git checkout master

cd ~/.config/ranger/plugins/ranger_fzf_filter || exit
git checkout main

cd ~/.config/ranger/plugins/ranger_devicons || exit
git checkout main

cd ~/.config/tmux/plugins/tmux-continuum || exit
git checkout master

cd ~/.config/tmux/plugins/tmux-fuzzback || exit
git checkout main

cd ~/.config/tmux/plugins/tmux-resurrect || exit
git checkout master

cd ~/.config/zsh/oh-my-zsh || exit
git checkout master

cd ~/.config/zsh/zsh-custom/plugins/fzf-tab || exit
git checkout master

cd ~/.config/zsh/zsh-custom/plugins/fzf-tab-source || exit
git checkout main

cd ~/.config/zsh/zsh-custom/plugins/zsh-autosuggestions || exit
git checkout master

cd ~/.config/zsh/zsh-custom/plugins/zsh-hist || exit
git checkout main

cd ~/.config/zsh/zsh-custom/themes/dircolors-solarized || exit
git checkout master

cd ~/.config/zsh/zsh-custom/themes/powerlevel10k || exit
git checkout master

popd || exit
