set path+=**

syntax enable                  " enable syntax highlighting (previously syntax on).
colorscheme desert             " set colorscheme
highlight Normal ctermbg=Grey ctermfg=White
filetype plugin indent on      " filetype detection[ON] plugin[ON] indent[ON]
filetype indent on             " activates indenting for files

set autoindent                 " auto-indent
set cmdheight=2
set clipboard^=unnamed,unnamedplus
set colorcolumn=80
set completeopt=menuone,noinsert,noselect
set cursorline
set expandtab                  " use spaces instead of tabs
set guicursor=
set hidden                     " But do highlight as you type your search.
set incsearch                  " But do highlight as you type your search.
set ignorecase                 " Make searches case-insensitive.
set laststatus=2               " last window always has a statusline
set nobackup
set noerrorbells               " no error bells!
set nofoldenable
set nohlsearch                 " Don't continue to highlight searched phrases.
set noswapfile
set nowrap                     " don't wrap text
set number                     " show line numbers
set relativenumber             " Always show info along bottom.
set ruler                      " Always show info along bottom.
set scrolloff=8                " always indent/outdent to the nearest tabstop
set shiftround                 " always indent/outdent to the nearest tabstop
set shiftwidth=4               " indent/outdent by 4 columns
set shortmess+=c
set signcolumn=yes             " indent at the start of a line spaces elsewhere
set smartcase                  " indent at the start of a line spaces elsewhere
set smartindent                " indent at the start of a line spaces elsewhere
set smarttab                   " use tabs at the start of a line spaces elsewhere
set tabstop=4 softtabstop=4    " tab spacing
set updatetime=50
set undodir=~/.config/nvim/undodir
set undofile
set undolevels=10000

if exists("&termguicolors") && exists("&winblend")
  syntax enable
  set termguicolors
  set winblend=0
  set wildoptions=pum
  set pumblend=5
  set background=dark
  " Use NeoSolarized
  let g:neosolarized_termtrans=1
  runtime ./colors/NeoSolarized.vim
  colorscheme NeoSolarized
endif

runtime ./plug.vim
runtime ./map.vim
