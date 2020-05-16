set nocompatible               " get rid of Vi compatibility mode. SET FIRST!
set t_Co=256                   " enable 256-color mode.
set number                     " show line numbers
set laststatus=2               " last window always has a statusline
set nohlsearch                 " Don't continue to highlight searched phrases.
set incsearch                  " But do highlight as you type your search.
set ignorecase                 " Make searches case-insensitive.
set ruler                      " Always show info along bottom.
set autoindent                 " auto-indent
set tabstop=4                  " tab spacing
set softtabstop=4              " unify
set shiftwidth=4               " indent/outdent by 4 columns
set shiftround                 " always indent/outdent to the nearest tabstop
set expandtab                  " use spaces instead of tabs
set smarttab                   " use tabs at the start of a line spaces elsewhere
set background=dark            " Use dark background
set nowrap                     " don't wrap text
colorscheme desert             " set colorscheme
filetype plugin indent on      " filetype detection[ON] plugin[ON] indent[ON]
filetype indent on             " activates indenting for files
syntax enable                  " enable syntax highlighting (previously syntax on).
noremap <Leader>s :update<CR>  " \s will save file
highlight Normal ctermbg=Black ctermfg=White
