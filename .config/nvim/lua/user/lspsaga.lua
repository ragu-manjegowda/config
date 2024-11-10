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
            winblend = 0,
            colors = {
                normal_bg = vim.g.gui_base02,
                title_bg = vim.g.gui_base03,
                fg = vim.g.gui_base2,
                red = vim.g.gui_red,
                magenta = vim.g.gui_magenta,
                orange = vim.g.gui_orange,
                yellow = vim.g.gui_yellow,
                green = vim.g.gui_green,
                cyan = vim.g.gui_violet,
                blue = vim.g.gui_blue,
                purple = vim.g.gui_cyan,
                gray = vim.g.gui_base0,
                white = vim.g.gui_base2,
                black = vim.g.gui_base02,
            }
        },
    })

    local map = vim.keymap.set

    -- LSP
    map('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
        { silent = true, desc = 'LSP jump to prev diagnostics' })

    map('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>',
        { silent = true, desc = 'LSP jump to next diagnostics' })

    map('n', '[e',
        "<cmd>lua require('lspsaga.diagnostic'):goto_prev({ " ..
        "severity = vim.diagnostic.severity.ERROR })<CR>",
        { silent = true, desc = 'LSP jump to prev error' })

    map('n', ']e',
        "<cmd>lua require('lspsaga.diagnostic'):goto_next({ " ..
        "severity = vim.diagnostic.severity.ERROR })<CR>",
        { silent = true, desc = 'LSP jump to next error' })

    map('n', '<leader>ep', '<cmd>Lspsaga show_line_diagnostics<CR>',
        { silent = true, desc = 'LSP line diagnostics' })

    map('n', '<leader>eP', '<cmd>Lspsaga show_cursor_diagnostics<CR>',
        { silent = true, desc = 'LSP cursor diagnostics' })

    map({ 'n', 'v' }, '<leader>lca', '<cmd>Lspsaga code_action<CR>',
        { silent = true, desc = 'LSP code action' })

    map('n', '<leader>ld', '<cmd>Lspsaga goto_definition<CR>',
        { silent = true, desc = 'LSP goto definition' })

    map('n', '<leader>lco', '<cmd>Lspsaga outline<CR>',
        { silent = true, desc = 'LSP code outline' })

    map('n', '<leader>lpf', '<cmd>Lspsaga peek_definition<CR>',
        { silent = true, desc = 'LSP peek function definition' })

    map('n', '<leader>lr', '<cmd>Lspsaga rename<CR>',
        { silent = true, desc = 'LSP rename in buffer' })

    map('n', '<leader>lrp', '<cmd>Lspsaga rename ++project<CR>',
        { silent = true, desc = 'LSP rename in project' })

    map('n', '<leader>lsy', '<cmd>Lspsaga finder<CR>',
        { silent = true, desc = 'LSP find symbols' })
end

return M
