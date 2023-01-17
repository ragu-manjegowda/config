local ok_status, NeoSolarized = pcall(require, "NeoSolarized")

-- If plugin is available leverage it (needed for lspsaga)
if ok_status then
    local theme = "light"

    -- Default Setting for NeoSolarized
    NeoSolarized.setup {
        style = theme,
        transparent = false
    }
else
    -- Notify user about missing plugin, go on to use static file from
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
        colorscheme NeoSolarized
    catch /^Vim\%((\a\+)\)\=:E18o
        colorscheme default
    endtry
]]

-- For whatever reason italic does not work, hence do the following to
-- force italic for those defined in colorscheme
local function update_hl(group, tbl)
    local old_hl = vim.api.nvim_get_hl_by_name(group, true)
    local new_hl = vim.tbl_extend('force', old_hl, tbl)
    vim.api.nvim_set_hl(0, group, new_hl)
end

update_hl('Comment', { italic = true })
update_hl('gitcommitComment', { italic = true })
