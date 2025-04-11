-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, saga = pcall(require, "lspsaga")
    if not res then
        vim.notify("lspsaga not found", vim.log.levels.ERROR)
        return
    end

    saga.setup({
        border_style = "rounded",
        callhierarchy = {
            keys = {
                tabe = '<leader><Tab>',
                expand_collaspe = '<CR>',
            },
        },
        definition = {
            edit = '<CR>',
            tabe = '<leader><Tab>',
        },
        diagnostic = {
            show_code_action = false,
        },
        finder = {
            tabe = '<leader><Tab>',
        },
        lightbulb = {
            enable = false
        },
        outline = {
            layout = "float"
        },
        symbol_in_winbar = {
            show_file = false,
        },
        ui = {
            -- border type can be single,double,rounded,solid,shadow.
            border = 'rounded',
            winblend = 0
        },
    })

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("Error loading user.utils", vim.log.levels.ERROR)
        return
    end

    local opts = function(desc)
        return {
            desc = "lspsaga: " .. desc
        }
    end

    -- LSP
    utils.keymap('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
        opts('LSP jump to prev diagnostics'))

    utils.keymap('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>',
        opts('LSP jump to next diagnostics'))

    utils.keymap('n', '[e',
        "<cmd>lua require('lspsaga.diagnostic'):goto_prev({ " ..
        "severity = vim.diagnostic.severity.ERROR })<CR>",
        opts('LSP jump to prev error'))

    utils.keymap('n', ']e',
        "<cmd>lua require('lspsaga.diagnostic'):goto_next({ " ..
        "severity = vim.diagnostic.severity.ERROR })<CR>",
        opts('LSP jump to next error'))

    utils.keymap('n', '<leader>ep', '<cmd>Lspsaga show_line_diagnostics<CR>',
        opts('LSP show line diagnostics'))

    utils.keymap('n', '<leader>eP', '<cmd>Lspsaga show_cursor_diagnostics<CR>',
        opts('LSP show cursor diagnostics'))

    utils.keymap({ 'n', 'v' }, '<leader>lca', '<cmd>Lspsaga code_action<CR>',
        opts('LSP code action'))

    utils.keymap('n', '<leader>ld', '<cmd>Lspsaga goto_definition<CR>',
        opts('LSP goto definition'))

    utils.keymap('n', '<leader>lco', '<cmd>Lspsaga outline<CR>',
        opts('LSP code outline'))

    utils.keymap('n', '<leader>lpf', '<cmd>Lspsaga peek_definition<CR>',
        opts('LSP peek function definition'))

    utils.keymap('n', '<leader>lr', '<cmd>Lspsaga rename<CR>',
        opts('LSP rename in buffer'))

    utils.keymap('n', '<leader>lrp', '<cmd>Lspsaga rename ++project<CR>',
        opts('LSP rename in project'))

    utils.keymap('n', '<leader>lsy', '<cmd>Lspsaga finder<CR>',
        opts('LSP find symbols'))
end

return M
