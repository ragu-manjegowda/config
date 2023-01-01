local vim = vim

local M = {}

function M.config()
    local res, saga = pcall(require, "lspsaga")
    if not res then
        vim.notify("lspsaga not found", vim.log.levels.ERROR)
        return
    end

    saga.init_lsp_saga({
        border_style = "rounded",
        finder_action_keys = {
            open = '<CR>',
            quit = 'q',
            tabe = '<leader>t',
        },
        code_action_keys = {
            exec = '<CR>',
            quit = 'q',
        },
        definition_action_keys = {
            edit = '<CR>',
            quit = 'q',
            tabe = '<leader>t',
        },
        symbol_in_winbar = {
            in_custom = true
        }
    })

    local map = vim.api.nvim_set_keymap

    -- LSP
    map('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
    { silent = true, desc = 'LSP jump to prev diagnostics' })

    map('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>',
    { silent = true, desc = 'LSP jump to next diagnostics' })

    map('n', '[e',
    "<cmd>lua require('lspsaga.diagnostic').goto_prev({ severity = vim.diagnostic.severity.ERROR })<CR>",
    { silent = true, desc = 'LSP jump to prev error' })

    map('n', ']e',
    "<cmd>lua require('lspsaga.diagnostic').goto_next({ severity = vim.diagnostic.severity.ERROR })<CR>",
    { silent = true, desc = 'LSP jump to next error' })

    map('i', '<C-k>', '<cmd>Lspsaga hover_doc<CR>',
    { silent = true, desc = 'LSP signature help' })

    map('n', '<C-k>', '<cmd>Lspsaga hover_doc<CR>',
    { silent = true, desc = 'LSP signature help' })

    map('n', '<leader>ep', '<cmd>Lspsaga show_line_diagnostics<CR>',
    { silent = true, desc = 'LSP line diagnostics' })

    map('n', '<leader>eP', '<cmd>Lspsaga show_cursor_diagnostics<CR>',
    { silent = true, desc = 'LSP cursor diagnostics' })

    map('n', '<leader>lca', '<cmd>Lspsaga code_action<CR>',
    { silent = true, desc = 'LSP code action' })

    map('n', '<leader>ld', '<cmd>Lspsaga lsp_finder<CR>',
    { silent = true, desc = 'LSP implementations' })

    map('n', '<leader>lco', '<cmd>Lspsaga outline<CR>',
    { silent = true, desc = 'LSP code outline' })

    map('n', '<leader>lpf', '<cmd>Lspsaga peek_definition<CR>',
    { silent = true, desc = 'LSP peek function definition' })

    map('n', '<leader>lr', '<cmd>Lspsaga rename<CR>',
    { silent = true, desc = 'LSP rename' })
end

return M
