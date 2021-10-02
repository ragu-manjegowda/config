" Define leader
let mapleader = " "

" Disable arrow keys in normal mode
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" Scroll horizontally
noremap <C-L> 5zl " Scroll 5 characters to the right
noremap <C-H> 5zh " Scroll 5 characters to the left

" Delete without yank
nnoremap <leader>d "_d

" Save with root permission
command! W w !sudo tee > /dev/null %

" ============ Key maps for tabs
" Open new empty tab
noremap <leader>n<Tab> :tabedit<CR>
noremap <leader><S-Tab> :tabprev<CR>
noremap <leader><Tab> :tabnext<CR>
" Close all tabs except current
noremap <leader>co :tabonly<CR>

" Quit
nnoremap <leader>q :q<CR>

" Map to navigate QuickFix list
nnoremap <leader>qo :copen<Return><C-w>T
noremap <C-n> :cn<CR>
noremap <C-p> :cp<CR>

augroup QuickFix
    " Open qf entry in vertical split
    au FileType qf nnoremap <buffer> <leader>v <C-w><CR><C-w>L
    " Open qf list in new tab
    au FileType qf nnoremap <buffer> <leader>t <C-w><CR><C-w>T
augroup END

" Open toggle undo tree
nnoremap <leader>ut :UndotreeToggle<CR>

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

" Get full path of the current buffer
nnoremap <leader>fp 1<C-g><CR>

