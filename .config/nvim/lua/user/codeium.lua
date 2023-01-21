local vim = vim

local M = {}

function M.before()
    vim.keymap.set('i', '<C-l>', function()
        return vim.fn['codeium#Clear']()
    end, { expr = true, desc = 'Codeium cancel suggestion' })

    vim.keymap.set('i', '<C-s>', function()
        return vim.fn['codeium#Accept']()
    end, { expr = true, desc = 'Codeium accept suggestion' })
end

return M
