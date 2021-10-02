" Status line
if !exists('*fugitive#statusline')
  set statusline=%F\ %m%r%h%w%y%{'['.(&fenc!=''?&fenc:&enc).':'.&ff.']'}[L%l/%L,C%03v]
  set statusline+=%=
  set statusline+=%{fugitive#statusline()}
endif

augroup GitStatus
    au filetype fugitive nmap <buffer> dv :Gtabedit <Plug><cfile><Bar>Gvdiffsplit<CR>
augroup END

" Git status in new tab
nnoremap <silent> <leader>gst :tab G<CR>

" Resolve merge conflict
nnoremap <silent> <leader>gpf :diffget //2<CR>
nnoremap <silent> <leader>gpj :diffget //3<CR>

