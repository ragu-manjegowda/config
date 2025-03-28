-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    local res, cmp, lspkind

    res, cmp = pcall(require, "cmp")
    if not res then
        vim.notify("cmp not found", vim.log.levels.ERROR)
        return
    end

    res, lspkind = pcall(require, "lspkind")
    if not res then
        vim.notify("lspkind not found", vim.log.levels.ERROR)
        return
    end

    local ELLIPSIS_CHAR = '…'
    local MAX_LABEL_WIDTH = 80
    local MIN_LABEL_WIDTH = 20

    cmp.setup {
        mapping = {
            ["<Tab>"] = cmp.mapping({
                c = function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
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
                c = function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
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
                { 'i' }
            ),

            ['<Up>'] = cmp.mapping(
                cmp.mapping.select_prev_item(
                    { behavior = cmp.SelectBehavior.Select }),
                { 'i' }
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

            ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
            ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
            ---@diagnostic disable-next-line: missing-parameter
            ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),

            ['<C-q>'] = cmp.mapping({
                i = cmp.mapping.close(), c = cmp.mapping.close()
            }),

            ['<CR>'] = cmp.mapping({
                i = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Insert, select = false
                }),
                c = function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            behavior = cmp.ConfirmBehavior.Replace, select = false
                        })
                    else
                        fallback()
                    end
                end
            }),
        },

        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'path' },
            { name = 'buffer' },
            { name = 'bazel' },
            { name = 'tags' }
        }),

        completion = {
            completeopt = 'menu,menuone,preview,noinsert',
            documentation = {}
        },

        formatting = {
            format = function(entry, vim_item)
                local label = vim_item.abbr
                local truncated_label = vim.fn.strcharpart(label, 0, MAX_LABEL_WIDTH)
                if truncated_label ~= label then
                    vim_item.abbr = truncated_label .. ELLIPSIS_CHAR
                elseif string.len(label) < MIN_LABEL_WIDTH then
                    local padding = string.rep(' ', MIN_LABEL_WIDTH - string.len(label))
                    vim_item.abbr = label .. padding
                end
                vim_item.kind = lspkind.presets.default[vim_item.kind] .. ' ' .. vim_item.kind
                vim_item.menu = ({
                    nvim_lsp = '[LSP]',
                    path = '[Path]',
                    buffer = '[Buffer]',
                    bazel = '[Bazel]',
                    tags = '[tags]'
                })[entry.source.name]

                return vim_item
            end,
            fields = { 'menu', 'abbr', 'kind' }
        },

        window = {
            completion = cmp.config.window.bordered {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            },
            documentation = cmp.config.window.bordered {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            },
        },
    }

    -- Use buffer source for `/`.
    cmp.setup.cmdline('/', {
        ---@diagnostic disable-next-line: assign-type-mismatch
        completion = { autocomplete = false },
        sources = {
            { name = 'buffer' }
        }
    })

    -- Use cmdline & path source for ':'.
    cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
            { name = 'path' },
            { name = 'cmdline' }
        })
    })

    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'text', 'mail', 'rmd', 'rst' },
        callback = function()
            cmp.setup.buffer {
                sources = {
                    { name = 'buffer' },
                    { name = 'path' },
                    { name = 'bazel' }
                }
            }
        end
    })
end

return M
