-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

---@class colorscheme
local M = {}

M.meta = {
    desc = "Set colorscheme",
    needs_setup = true,
}

function M.setup()
    -- Set colorscheme to NeoSolarized
    vim.cmd [[
        " Set background
        set background=light

        try
            " Use NeoSolarized
            let g:neosolarized_contrast = "high"
            let g:neosolarized_diffmode = "high"
            let g:neosolarized_italic=1
            let g:neosolarized_termcolors=256
            let g:neosolarized_termtrans=1
            let g:neosolarized_visibility = "high"
            colorscheme NeoSolarized
        catch /^Vim\%((\a\+)\)\=:E185/
            colorscheme default
        endtry
    ]]
end

return M
