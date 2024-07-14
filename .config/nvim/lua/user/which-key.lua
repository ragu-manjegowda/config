-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    -- If we do not wish to wait for timeoutlen
    vim.api.nvim_set_keymap('n', '<Leader>?', "<Esc>:WhichKey '' n<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', '<Leader>?', "<Esc>:WhichKey '' v<CR>", { noremap = true, silent = true })

    -- https://github.com/folke/which-key.nvim#colors
    vim.cmd([[highlight default link WhichKey          htmlH1]])
    vim.cmd([[highlight default link WhichKeySeperator String]])
    vim.cmd([[highlight default link WhichKeyGroup     Keyword]])
    vim.cmd([[highlight default link WhichKeyDesc      Include]])
    vim.cmd([[highlight default link WhichKeyFloat     CursorLine]])
    vim.cmd([[highlight default link WhichKeyValue     Comment]])
end

function M.config()
    local status_ok, whichkey = pcall(require, "which-key")
    if not status_ok then
        vim.notify("which-key not found", vim.log.levels.ERROR)
        return
    end

    whichkey.setup {
        delay = 500,
        plugins = {
            marks = true, -- shows a list of your marks on ' and `
            -- shows your registers on " in NORMAL or <C-r> in INSERT mode
            -- the presets plugin, adds help for a bunch of default
            -- keybindings in Neovim. No actual key bindings are created
            registers = false,
            spelling = {
                -- enabling this will show WhichKey when pressing z= to
                -- select spelling suggestions
                enabled = true,
                -- how many suggestions should be shown in the list?
                suggestions = 20
            },
            presets = {
                -- adds help for operators like d, y, ... and registers them
                -- for motion / text object completion
                operators = false,
                motions = false, -- adds help for motions
                -- help for text objects triggered after entering an operator
                text_objects = false,
                windows = true, -- default bindings on <c-w>
                nav = true, -- misc bindings to work with windows
                z = true, -- bindings for folds, spelling and others prefixed with z
                g = true -- bindings for prefixed with g
            }
        },
        -- add operators that will trigger motion and text object completion
        -- to enable all native operators, set the preset / operators plugin above
        operators = { gc = "Comments" },
        key_labels = {
            -- override the label used to display some keys.
            -- It doesn't effect WK in any other way.
            -- For example:
            ["<space>"] = "SPC",
            ["<cr>"] = "RET",
            ["<tab>"] = "TAB"
        },
        icons = {
            -- symbol used in the command line area that shows your active key combo
            breadcrumb = "»",
            separator = "➜", -- symbol used between a key and it's label
            group = "+" -- symbol prepended to a group
        },
        window = {
            border = "none", -- none, single, double, shadow
            position = "bottom", -- bottom, top
            margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
            padding = { 1, 1, 1, 1 } -- extra window padding [top, right, bottom, left]
        },
        layout = {
            height = { min = 4, max = 25 }, -- min and max height of the columns
            width = { min = 20, max = 50 }, -- min and max width of the columns
            spacing = 5 -- spacing between columns
        },
        -- hide mapping boilerplate
        hidden = {
            "<silent>", "<cmd>", "<Cmd>", "<CR>", "call",
            "lua", "^:", "^ "
        },
        -- show help message on the command line when the popup is visible
        show_help = true,
        -- automatically setup triggers
        triggers = "auto"
        -- triggers = {"<leader>"} -- or specifiy a list manually
    }
end

return M
