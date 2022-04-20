local vim = vim

local M = {}

function M.config()
    require'FTerm'.setup({
        border = 'double',
        dimensions  = {
            height = 0.9,
            width = 0.9,
        },
    })

    local ftzsh = require("FTerm"):new({
        ft = 'fterm_zsh', -- You can also override the default filetype, if you want
        cmd = "zsh",
        dimensions = {
            height = 0.9,
            width = 0.9
        }
    })

     -- Use this to toggle zsh in a floating terminal
    function _G.__fterm_zsh()
        ftzsh:toggle()
    end

    -- Example keybindings
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    map('n', '<Leader>ts', '<CMD>lua __fterm_zsh()<CR>', opts)
    map('t', '<Leader>ts', '<C-\\><C-n><CMD>lua __fterm_zsh()<CR>', opts)
end

return M

