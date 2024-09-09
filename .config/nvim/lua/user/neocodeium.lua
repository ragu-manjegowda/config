-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, neocodeium = pcall(require, "neocodeium")
    if not res then
        vim.notify("neocodeium not found", vim.log.levels.ERROR)
        return
    end

    neocodeium.setup({
        filetypes = {
            TelescopePrompt = false,
            ["dap-repl"] = false,
        },
    })

    local map = vim.keymap.set

    map('i', '<C-e>',
        neocodeium.accept,
        { silent = true, desc = 'Codeium suggestion accept' })

    map('i', '<M-e>',
        neocodeium.accept_line,
        { silent = true, desc = 'Codeium suggestion accept line' })

    map('i', '<M-f>',
        neocodeium.accept_word,
        { silent = true, desc = 'Codeium suggestion accept word' })

    map('i', '<M-i>',
        neocodeium.cycle_or_complete,
        { silent = true, desc = 'Codeium suggestion next' })

    map('i', '<M-o>',
        function()
            neocodeium.cycle_or_complete(-1)
        end,
        { silent = true, desc = 'Codeium suggestion prev' })

    map('i', '<C-x>',
        neocodeium.clear,
        { silent = true, desc = 'Codeium suggestion clear' })
end

return M
