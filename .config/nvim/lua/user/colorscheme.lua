local ok_status, NeoSolarized = pcall(require, "NeoSolarized")

-- If plugin is available leverage it
if ok_status then
    local theme = "light"

    -- Default Setting for NeoSolarized
    NeoSolarized.setup {
        style = theme,
        transparent = false
    }
else
    -- Notify user about missing plugin, go on to use fallback static file from
    -- ~/.config/nvim/colors/NeoSolarized.vim
    vim.notify("NeoSolarized not found", vim.log.levels.WARN)
end

-- Set colorscheme to NeoSolarized
vim.cmd [[

    " Set background
    set background=dark

    try
        syntax enable
        set background=dark
        " Use NeoSolarized
        let g:neosolarized_termtrans=1
        let g:neosolarized_contrast = "high"
        let g:neosolarized_visibility = "high"
        let g:neosolarized_termcolors=256
        let g:neosolarized_bold = 1
        let g:neosolarized_underline = 1
        let g:neosolarized_italic = 0
        colorscheme NeoSolarized
    catch /^Vim\%((\a\+)\)\=:E18o
        colorscheme default
    endtry
]]
