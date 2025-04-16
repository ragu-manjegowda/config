-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.api.nvim_set_keymap(
        "n",
        "<leader>sc",
        ':lua require("specs").show_specs()<CR>',
        { noremap = true, silent = true }
    )
end

function M.config()
    local res, specs = pcall(require, "specs")
    if not res then
        vim.notify("specs not found", vim.log.levels.ERROR)
        return
    end

    specs.setup {
        show_jumps       = false,
        min_jump         = 30,
        popup            = {
            delay_ms = 0, -- delay before popup displays
            inc_ms = 5,   -- time increments used for fade/resize effects
            blend = 10,   -- starting blend, between 0-100 (fully transparent), see :h winblend
            width = 50,
            winhl = "PMenu",
            fader = require("specs").linear_fader,
            resizer = require("specs").shrink_resizer
        },
        ignore_filetypes = {},
        ignore_buftypes  = {
            nofile = true,
        },
    }
end

return M
