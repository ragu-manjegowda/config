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
vnoremap <leader>d "_d
nnoremap x "_x
nnoremap <Del> "_x

" Keep it centered
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" Moving text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '>-2<CR>gv=gv
inoremap <C-j> <esc>:m .+1<CR>==i
inoremap <C-k> <esc>:m .-2<CR>==i
nnoremap <leader>j :m .+1<CR>==
nnoremap <leader>k :m .-2<CR>==

" Save with root permission
command! W w !sudo tee > /dev/null %

" ============ Key maps for tabs
" Open new empty tab
noremap <leader>n<Tab> :tabedit<CR>
" Close all tabs except current
noremap <leader>co :tabonly<CR>
" Open terminal in new tab
noremap <leader>zsh :tabnew term://zsh<CR>
noremap <leader>bash :tabnew term://bash<CR>

" Terminal exit insert mode
tnoremap <ESC><ESC> <C-\><C-n>

" Exit insert mode
inoremap jj <ESC>

" Write
nnoremap <leader>w :w<CR>

" Quit
nnoremap <leader>q :q<CR>

" Map to navigate QuickFix list
nnoremap <leader>qo :copen<Return><C-w>T

augroup QuickFix
    " Open qf entry in vertical split
    au FileType qf nnoremap <buffer> <leader>v <C-w><CR><C-w>L
    " Open qf list in new tab
    au FileType qf nnoremap <buffer> <leader><Tab> <C-w><CR><C-w>T
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

