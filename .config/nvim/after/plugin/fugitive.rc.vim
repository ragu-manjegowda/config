" Status line
if !exists('*fugitive#statusline')
  set statusline=%F\ %m%r%h%w%y%{'['.(&fenc!=''?&fenc:&enc).':'.&ff.']'}[L%l/%L,C%03v]
  set statusline+=%=
  set statusline+=%{fugitive#statusline()}
endif

augroup GitStatus
    au filetype fugitive nmap <buffer> <leader>gdv :Gtabedit <Plug><cfile><Bar>Gvdiffsplit<CR>
augroup END

" Git status in new tab
nnoremap <silent> <leader>gca :tab Git commit --amend<CR>
nnoremap <silent> <leader>gcan :Git commit --amend --no-edit<CR>
nnoremap <silent> <leader>gcm :tab Git commit -s<CR>
nnoremap <silent> <leader>gfa :Git fetch --all --prune<CR>
nnoremap <silent> <leader>glf :tab Git log --oneline --decorate --graph -- %<CR>
nnoremap <silent> <leader>glg :tab Git log<CR>
nnoremap <silent> <leader>gpulla :Git pull --rebase --autostash<CR>
nnoremap <silent> <leader>gpush :Git push<CR>
nnoremap <silent> <leader>gst :tab G<CR>

" Resolve merge conflict
nnoremap <silent> <leader>gpf :diffget //2<CR>
nnoremap <silent> <leader>gpj :diffget //3<CR>

lua <<EOF

-- Register mappings description with which-key
local wk = require("which-key")

wk.register({
  g = {
    name = "Git",
    dv = "Git diff view in new tab",
    lf = "Git log current file in new tab",
    lp = "Git log in new tab",
    pf = "Git merge apply left diff",
    pj = "Git merge apply right diff"
  },
}, { prefix = "<leader>" })

EOF
