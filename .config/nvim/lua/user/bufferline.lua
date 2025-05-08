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
            -- Buffer line background
            fill               = { bg = colors.base2 },

            -- Text and icon (non-selected tab) highlight group
            background         = { fg = colors.base2, bg = colors.base1 },

            -- Non-selected tab highlight group
            modified           = { fg = colors.base2, bg = colors.base1 },
            numbers            = { fg = colors.base2, bg = colors.base1 },
            separator          = { fg = colors.base2, bg = colors.base1 },

            -- Selected tab highlight group
            buffer_selected    = { fg = colors.magenta, bg = colors.base3 },
            modified_selected  = { fg = colors.magenta, bg = colors.base3 },
            numbers_selected   = { fg = colors.magenta, bg = colors.base3 },
            separator_selected = { fg = colors.base2, bg = colors.base3 }
        }
    else
        hl = {
            -- Buffer line background
            fill               = { bg = colors.base02 },

            -- Text and icon (non-selected tab) highlight group
            background         = { fg = colors.base02, bg = colors.base01 },

            -- Non-selected tab highlight group
            modified           = { fg = colors.base02, bg = colors.base01 },
            numbers            = { fg = colors.base02, bg = colors.base01 },
            separator          = { fg = colors.base02, bg = colors.base01 },

            -- Selected tab highlight group
            buffer_selected    = { fg = colors.magenta, bg = colors.base03 },
            modified_selected  = { fg = colors.magenta, bg = colors.base03 },
            numbers_selected   = { fg = colors.magenta, bg = colors.base03 },
            separator_selected = { fg = colors.base02, bg = colors.base03 }
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
                local icon, hlg = web_devicons.get_icon_by_filetype(
                    element.filetype, { default = false })
                return icon, hlg
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
