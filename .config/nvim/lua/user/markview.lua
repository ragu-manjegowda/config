-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, markview = pcall(require, "markview")
    if not res then
        vim.notify("markview not found", vim.log.levels.ERROR)
        return
    end

    markview.setup({
        modes = { "c", "n", "no", "v" },
        callbacks = {
            on_enable = function(_, win)
                vim.wo[win].conceallevel = 2;
                vim.wo[win].concealcursor = "n";
            end
        },
        --- Configuration for custom block quotes
        block_quotes = {
            callouts = {
                {
                    match_string = { "Important" },
                    hl = "MarkviewBlockQuoteSpecial",
                    preview = "󰨄 Important",
                    preview_hl = nil,
                    title = true,
                    icon = "󰨄 ",
                    border = "▋",
                    border_hl = nil
                },
                {
                    match_string = { "Reference", "References" },
                    hl = "MarkviewBlockQuoteNote",
                    preview = " References",
                    preview_hl = nil,
                    title = true,
                    icon = " ",
                    border = "▋",
                    border_hl = nil
                },
                {
                    match_string = { "Resource", "Resources" },
                    hl = "MarkviewBlockQuoteSpecial",
                    preview = " Resources",
                    preview_hl = nil,
                    title = true,
                    icon = " ",
                    border = "▋",
                    border_hl = nil
                }
            }
        },
        highlight_groups = {
            {
                group_name = "Heading1",
                value = {
                    fg = vim.g.gui_red,
                    bg = vim.g.gui_base02
                }
            },
            {
                group_name = "Heading2",
                value = {
                    fg = vim.g.gui_green,
                    bg = vim.g.gui_base02
                }
            },
            {
                group_name = "Heading3",
                value = {
                    fg = vim.g.gui_yellow,
                    bg = vim.g.gui_base02
                }
            },
            {
                group_name = "Heading4",
                value = {
                    fg = vim.g.gui_orange,
                    bg = vim.g.gui_base02
                }
            },
            {
                group_name = "Heading5",
                value = {
                    fg = vim.g.gui_cyan,
                    bg = vim.g.gui_base02
                }
            },
            {
                group_name = "MarkviewCode",
                value = {
                    bg = vim.g.gui_base02
                },
            },
            {
                group_name = "MarkviewInlineCode",
                value = {
                    fg = vim.g.gui_cyan,
                    bg = vim.g.gui_base02
                }
            }
        }
    })
end

return M
