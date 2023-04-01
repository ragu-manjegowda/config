-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.g.codeium_disable_bindings = 1

    vim.g.codeium_filetypes = {
        TelescopePrompt = false
    }

    vim.keymap.set('i', '<C-e>', function()
        return vim.fn['codeium#Accept']()
    end, { expr = true, silent = true, desc = 'Codeium accept suggestion' })

    vim.keymap.set('i', '<C-;>', function()
        return vim.fn['codeium#CycleCompletions'](1)
    end, { expr = true, silent = true, desc = 'Codeium next suggestion' })

    vim.keymap.set('i', '<C-,>', function()
        return vim.fn['codeium#CycleCompletions'](-1)
    end, { expr = true, silent = true, desc = 'Codeium prev suggestion' })

    vim.keymap.set('i', '<C-x>', function()
        return vim.fn['codeium#Clear']()
    end, { expr = true, silent = true, desc = 'Codeium clear suggestion' })
end

return M
