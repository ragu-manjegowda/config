" Define leader
let mapleader = " "

" Disable arrow keys in normal mode
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" Delete without yank
nnoremap <leader>d "_d

" Save with root permission
command! W w !sudo tee > /dev/null %

" ============ Key maps for tabs
" Open new empty tab
noremap <leader>n<Tab> :tabedit<Return>
noremap <leader><S-Tab> :tabprev<Return>
noremap <leader><Tab> :tabnext<Return>
" Close all tabs except current
noremap <leader>co :tabonly<Return>

" Quit
nnoremap <leader>q :q<Return>

augroup QuickFix
    " Open qf entry in new tab
    au FileType qf nnoremap <buffer> <leader><Tab> <C-w><Enter><C-w>T
    " Open qf entry in vertical split
    au FileType qf nnoremap <buffer> <leader>v <C-w><Enter><C-w>L
    " Open qf list in new tab
    au FileType qf nnoremap <buffer> <leader>t <C-w>T
augroup END

" Open toggle undo tree
nnoremap <leader>ut :UndotreeToggle<CR>

" Telescope fuzzy finder shortcuts
nnoremap <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>pw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
nnoremap <leader>pf :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>pq :lua require('telescope.builtin').quickfix()<cr>

" Delete space at the end
augroup StripTrailingSpace
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
nnoremap <silent> <leader>oh :FSSplitRight<CR>

nnoremap <silent> <leader>gst :tab G<CR>

nnoremap <leader>fp 1<C-g><CR>

