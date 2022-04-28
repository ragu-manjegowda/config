local vim = vim

local M = {}

function M.config()
    local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    local cmp = require('cmp')
    local lspkind = require('lspkind')

    cmp.setup {
        -- You must set mapping if you want.
        mapping = {
            ["<Tab>"] = cmp.mapping({
                c = function()
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        cmp.complete()
                    end
                end,
                i = function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end
            }),
            ["<S-Tab>"] = cmp.mapping({
                c = function()
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        cmp.complete()
                    end
                end,
                i = function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end
            }),
            ['<Down>'] = cmp.mapping(
                cmp.mapping.select_next_item(
                    { behavior = cmp.SelectBehavior.Select }),
                    {'i'}
            ),
            ['<Up>'] = cmp.mapping(
                cmp.mapping.select_prev_item(
                    { behavior = cmp.SelectBehavior.Select }),
                    {'i'}
            ),
            ['<C-n>'] = cmp.mapping({
                c = function()
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                    else
                        vim.api.nvim_feedkeys(t('<Down>'), 'n', true)
                    end
                end,
                i = function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                    else
                        fallback()
                    end
                end
            }),
            ['<C-p>'] = cmp.mapping({
                c = function()
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                    else
                        vim.api.nvim_feedkeys(t('<Up>'), 'n', true)
                    end
                end,
                i = function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                    else
                        fallback()
                    end
                end
            }),
            ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), {'i', 'c'}),
            ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), {'i', 'c'}),
            ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), {'i', 'c'}),
            ['<C-e>'] = cmp.mapping({
              i = cmp.mapping.close(), c = cmp.mapping.close() }),
            ['<CR>'] = cmp.mapping({
                i = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Insert, select = false }),
                c = function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            behavior = cmp.ConfirmBehavior.Replace, select = false })
                    else
                        fallback()
                    end
                end
            }),
        },

        -- You should specify your *installed* sources.
        sources = {
            { name = 'nvim_lsp' },
            { name = 'path' },
            { name = 'treesitter' },
            { name = 'buffer' },
        },

        completion = {
            completeopt = 'menu,menuone,noinsert',
            documentation = {}
        },

        formatting = {
            format = function(entry, vim_item)
            vim_item.kind = lspkind.presets.default[vim_item.kind] .. ' ' .. vim_item.kind
            vim_item.menu = ({
                nvim_lsp = '[LSP]',
                path = '[Path]',
                treesitter = '[Treesitter]',
                buffer = '[Buffer]',
            })[entry.source.name]

            return vim_item
            end
        }
    }

    -- Use buffer source for `/`.
    cmp.setup.cmdline('/', {
        completion = { autocomplete = false },
        sources = {
            -- { name = 'buffer' }
            { name = 'buffer', option = { keyword_pattern = [=[[^[:blank:]].*]=] } }
        }
    })

    -- Use cmdline & path source for ':'.
    cmp.setup.cmdline(':', {
        completion = { autocomplete = false },
        sources = cmp.config.sources({
            { name = 'path' }
            }, {
            { name = 'cmdline' }
        })
    })

    vim.cmd [[
        " Setup buffer configuration (nvim-lua source only enables in Lua filetype).
        autocmd FileType lua lua require'cmp'.setup.buffer {
        \   sources = {
        \     { name = 'buffer' },
        \     { name = 'nvim_lua' },
        \   },
        \ }
    ]]
end

return M
