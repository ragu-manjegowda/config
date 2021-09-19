let g:gutentags_cache_dir = '/tmp/nvim/gutentags'
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_trace = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_ctags_auto_set_tags = 0
let g:gutentags_project_root = [ '.git' ]

if executable('rg')
  let g:gutentags_file_list_command = 'rg --files'
endif

" Clear the cache
command! -nargs=0 GutentagsClearCache call system('rm ' . g:gutentags_cache_dir . '/*')

