-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local res, bufferline = pcall(require, "bufferline")
if not res then
    vim.notify("bufferline not found", vim.log.levels.ERROR)
    return
end

local web_devicons
res, web_devicons = pcall(require, "nvim-web-devicons")
if not res then
    vim.notify("nvim-web-devicons not found", vim.log.levels.WARN)
    return
end

local colors, hl
colors = require("user.utils").get_colors()

if colors == nil then
    hl = {}
else
    if vim.o.background == "light" then
        hl = {
            background         = { fg = colors.base2, bg = colors.base0 },
            buffer_selected    = { fg = colors.magenta, bg = colors.base2 },
            fill               = { bg = colors.base1 },
            modified           = { fg = colors.base2, bg = colors.base0 },
            modified_selected  = { fg = colors.magenta, bg = colors.base2 },
            numbers            = { fg = colors.base2, bg = colors.base0 },
            numbers_selected   = { fg = colors.magenta, bg = colors.base2 },
            separator          = { fg = colors.base1, bg = colors.base0 },
            separator_selected = { fg = colors.base1, bg = colors.base2 },
            tab_close          = { bg = colors.base1 },
        }
    else
        hl = {
            background         = { fg = colors.base02, bg = colors.base00 },
            buffer_selected    = { fg = colors.magenta, bg = colors.base02 },
            fill               = { bg = colors.base01 },
            modified           = { fg = colors.base02, bg = colors.base00 },
            modified_selected  = { fg = colors.magenta, bg = colors.base02 },
            numbers            = { fg = colors.base02, bg = colors.base00 },
            numbers_selected   = { fg = colors.magenta, bg = colors.base02 },
            separator          = { fg = colors.base01, bg = colors.base00 },
            separator_selected = { fg = colors.base01, bg = colors.base02 },
            tab_close          = { bg = colors.base01 },
        }
    end
end

local M = {}

function M.config()
    bufferline.setup({
        highlights = hl,
        options = {
            mode = "tabs",
            numbers = "ordinal",
            indicator = {
                icon = "▎",
                style = "icon"
            },
            buffer_close_icon = "",
            modified_icon = "●",
            close_icon = "",
            left_trunc_marker = "",
            right_trunc_marker = "",
            diagnostics = false,
            custom_filter = nil,
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    highlight = "Directory",
                    separator = true
                },
                {
                    text = "UNDOTREE",
                    filetype = "undotree",
                    text_align = "center",
                    separator = true
                },
                {
                    text = "TagBar",
                    filetype = "tagbar",
                    text_align = "center",
                    separator = true
                },
                {
                    text = "Code Outline",
                    filetype = "lspsagaoutline",
                    text_align = "center",
                    separator = true
                },
                {
                    text = " DIFF VIEW",
                    filetype = "DiffviewFiles",
                    text_align = "center",
                    separator = true
                }
            },
            color_icons = true,
            show_buffer_close_icons = false,
            get_element_icon = function(element)
                local icon, hl = web_devicons.get_icon_by_filetype(
                    element.filetype, { default = false })
                return icon, hl
            end,
            show_tab_indicators = false,
            show_duplicate_prefix = true,
            persist_buffer_sort = true,
            separator_style = "slant",
            enforce_regular_tabs = true,
            always_show_bufferline = true,
            hover = {
                enabled = false,
            },
            sort_by = nil
        }
    })
end

return M
