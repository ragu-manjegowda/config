let g:gutentags_cache_dir = expand('~/.config/nvim/misc/gutentags')
let g:gutentags_gtags_dbpath = expand('~/.config/nvim/misc/gutentags')
let g:gutentags_modules = ['ctags', 'gtags_cscope']
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_trace = 0
" change focus to quickfix window after search
let g:gutentags_plus_switch = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_ctags_auto_set_tags = 0
let g:gutentags_project_root = [ '.git' ]

if executable('rg')
  let g:gutentags_file_list_command = 'rg --files'
endif

" Clear the cache
command! -nargs=0 GutentagsClearCache call system('rm ' . g:gutentags_cache_dir . '/*')

" Remaps
let g:gutentags_plus_nomap = 1

" Find symbols
noremap <silent> <leader>gsy :GscopeFind s <C-R><C-W><cr>
" Find definitions
noremap <silent> <leader>gd :GscopeFind g <C-R><C-W><cr>
" Find called by this function
noremap <silent> <leader>gc :GscopeFind d <C-R><C-W><cr>
" Find calling this function
noremap <silent> <leader>gC :GscopeFind c <C-R><C-W><cr>
" Find files including this file
noremap <silent> <leader>gi :GscopeFind i <C-R>=expand("<cfile>")<cr><cr>
" Find where this symbol is assigned value
noremap <silent> <leader>ga :GscopeFind a <C-R><C-W><cr>

