local vim = vim

local M = {}

function M.config()
    local res, saga = pcall(require, "lspsaga")
    if not res then
        vim.notify("lspsaga not found", vim.log.levels.ERROR)
        return
    end

    -- Setup SagaUI colors
    local colors
    res, colors = pcall(require, "NeoSolarized.colors")
    if not res then
        vim.notify("NeoSolarized.colors not found", vim.log.levels.ERROR)
        return
    end

    colors = colors.setup()

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
        outline = {
            keys = {
                expand_collaspe = '<CR>',
            }
        },
        symbol_in_winbar = {
            show_file = false,
        },
        ui = {
            -- border type can be single,double,rounded,solid,shadow.
            border = 'rounded',
            winblend = 0,
            colors = {
                --float window normal bakcground color
                normal_bg = colors.bg1,
                --title background color
                title_bg = colors.bg4,
                red = colors.red,
                magenta = colors.aqua,
                orange = colors.orange,
                yellow = colors.yellow,
                green = colors.green,
                cyan = colors.violet,
                blue = colors.blue,
                purple = colors.purple,
                white = colors.yellow,
                black = colors.orange,
            }
        },
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
