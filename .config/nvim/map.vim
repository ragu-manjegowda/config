" Define leader
let mapleader = " "

" Disable arrow keys in normal mode
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" Open toggle undo tree
nnoremap <leader>u :UndotreeToggle<CR>

" Telescope fuzzy finder shortcuts
nnoremap <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>pw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
nnoremap <leader>pf :lua require('telescope.builtin').find_files()<CR>

" Delete space at the end
augroup RAGU
    autocmd!
    autocmd BufWritePre * %s/\s\+$//e
augroup END

" Open man page
function! s:RaguCppMan()
    let old_isk = &iskeyword
    setl iskeyword+=:
    let str = expand("<cword>")
    let &l:iskeyword = old_isk
    execute system("tmux split-window cppman " . str)
endfunction
command! RaguCppMan :call s:RaguCppMan()
au FileType cpp nnoremap <leader>man :RaguCppMan<CR>

" Zoom / Restore window
function! s:ZoomToggle() abort
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <silent> <leader>z :ZoomToggle<CR>


" Switch between header and source file
au BufEnter *.h  let b:fswitchdst = "c,cpp,cc,m"
au BufEnter *.cc let b:fswitchdst = "h,hpp"
" Switch between header and source file not in same directory
au BufEnter *.h let b:fswitchdst = 'c,cpp,m,cc' | let b:fswitchlocs = 'reg:|include.*|src/**|'
nnoremap <silent> <leader>o :FSSplitRight<cr>

