vim.cmd [[
    try
        syntax enable
        set background=dark
        " Use NeoSolarized
        let g:neosolarized_termtrans=1
        let g:neosolarized_contrast = "high"
        let g:neosolarized_visibility = "high"
        let g:neosolarized_termcolors=256
        runtime ../colors/NeoSolarized.vim
        colorscheme NeoSolarized
    catch /^Vim\%((\a\+)\)\=:E185/
        colorscheme default
        set background=dark
    endtry
]]
