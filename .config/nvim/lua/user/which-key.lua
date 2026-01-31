-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    -- If we do not wish to wait for timeoutlen
    vim.api.nvim_set_keymap("n", "<Leader>?", "<Esc>:WhichKey '' n<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<Leader>?", "<Esc>:WhichKey '' v<CR>", { noremap = true, silent = true })
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
            marks = true,
            registers = true,
            spelling = {
                enabled = true,
                suggestions = 20
            },
            presets = {
                text_objects = false,
                windows = true,
                nav = true,
                z = true,
                g = true
            }
        },
        win = {
            border = "rounded",
        },
        replace = {
            key = {
                { "<Space>", "SPC" },
                { "<CR>", "RET" },
                { "<Tab>", "TAB" }
            }
        },
        icons = {
            breadcrumb = "»",
            separator = "➜",
            group = "+"
        },
        layout = {
            width = { min = 20, max = 50 },
            spacing = 5
        },
        show_help = true,
    }
end

return M
