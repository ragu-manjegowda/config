-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, noice = pcall(require, "noice")
    if not res then
        vim.notify("noice not found", vim.log.levels.ERROR)
        return
    end

    local notify
    res, notify = pcall(require, "notify")
    if not res then
        vim.notify("notify not found", vim.log.ERROR)
        return
    else
        ---@diagnostic disable-next-line: undefined-field
        notify.setup({
            background_colour = "#000000"
        })
    end

    noice.setup({
        lsp = {
            hover = { enabled = false },
            signature = { enabled = false }
        },
        presets = {
            bottom_search = true,         -- use a classic bottom cmdline for search
            command_palette = true,       -- position the cmdline and popupmenu together
            long_message_to_split = true, -- long messages will be sent to a split
            inc_rename = false,           -- enables an input dialog for inc-rename.nvim
            lsp_doc_border = false,       -- add a border to hover docs and signature help
        }
    })

    local map = vim.keymap.set

    map('n', '<leader>nd', '<cmd>Noice dismiss<CR>',
        { silent = true, desc = 'Noice dismiss' })

    map('n', '<leader>nm', '<cmd>Noice<CR><C-W>T',
        { silent = true, desc = 'Noice messages' })
end

return M
