-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.opts()
    return {
        keymap = {
            preset = "default",

            ['<M-k>'] = { 'scroll_documentation_up', 'fallback' },
            ['<M-j>'] = { 'scroll_documentation_down', 'fallback' }
        },
        cmdline = {
            keymap = {
                preset = "inherit"
            }
        },
        completion = {
            accept = {
                auto_brackets = {
                    enabled = false
                }
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 500,
                window = {
                    border = "rounded"
                }
            },
            keyword = {
                range = "full"
            },
            list = {
                selection = {
                    preselect = false, auto_insert = true
                }
            },
            menu = {
                border = "rounded",
                draw = {
                    columns = {
                        {
                            "kind_icon",
                            "label",
                            gap = 2
                        },
                        {
                            "label_description",
                            "kind",
                            gap = 2
                        }
                    },
                    components = {
                        label = {
                            text = function(ctx)
                                return require("colorful-menu").blink_components_text(ctx)
                            end,
                            highlight = function(ctx)
                                return require("colorful-menu").blink_components_highlight(ctx)
                            end,
                        },
                    },
                    treesitter = {
                        "lsp"
                    }
                },
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        snippets = { preset = "default" },
        signature = { enabled = false }
    }
end

return M
