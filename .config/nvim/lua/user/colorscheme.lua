-- Set colorscheme to NeoSolarized
vim.cmd [[

    " Set background
    set background=light

    try
        syntax enable
        " Use NeoSolarized
        let g:neosolarized_termtrans=1
        let g:neosolarized_contrast = "high"
        let g:neosolarized_visibility = "high"
        let g:neosolarized_termcolors=256
        colorscheme NeoSolarized
    catch /^Vim\%((\a\+)\)\=:E185/
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
