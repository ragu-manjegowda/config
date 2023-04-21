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

vim.api.nvim_set_hl(0, 'bufferline_offset',
    {
        fg = vim.g.gui_base03,
        bg = vim.g.gui_base01,
        bold = true,
        italic = true
    })

local M = {}

function M.config()
    bufferline.setup({
        highlights = {
            tab_close = {
                bg = vim.g.gui_base01
            },
            fill = {
                bg = vim.g.gui_base01
            },
            background = {
                fg = vim.g.gui_base02,
                bg = vim.g.gui_base00
            },
            modified = {
                fg = vim.g.gui_base02,
                bg = vim.g.gui_base00
            },
            numbers = {
                fg = vim.g.gui_base02,
                bg = vim.g.gui_base00
            },
            separator = {
                fg = vim.g.gui_base01,
                bg = vim.g.gui_base00
            },
            buffer_selected = {
                fg = vim.g.gui_magenta,
                bg = vim.g.gui_base02
            },
            modified_selected = {
                fg = vim.g.gui_magenta,
                bg = vim.g.gui_base02
            },
            numbers_selected = {
                fg = vim.g.gui_magenta,
                bg = vim.g.gui_base02
            },
            separator_selected = {
                fg = vim.g.gui_base01,
                bg = vim.g.gui_base02
            },
        },
        options = {
            mode = "tabs",
            numbers = "ordinal",
            indicator = {
                icon = '▎',
                style = 'icon'
            },
            buffer_close_icon = '',
            modified_icon = '●',
            close_icon = '',
            left_trunc_marker = '',
            right_trunc_marker = '',
            diagnostics = false,
            custom_filter = nil,
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    highlight = 'bufferline_offset',
                    separator = true
                },
                {
                    text = 'UNDOTREE',
                    filetype = 'undotree',
                    text_align = "center",
                    highlight = 'bufferline_offset',
                    separator = true
                },
                {
                    text = 'TagBar',
                    filetype = 'tagbar',
                    text_align = "center",
                    highlight = 'bufferline_offset',
                    separator = true
                },
                {
                    text = 'Code Outline',
                    filetype = 'lspsagaoutline',
                    text_align = "center",
                    highlight = 'bufferline_offset',
                    separator = true
                },
                {
                    text = ' DIFF VIEW',
                    filetype = 'DiffviewFiles',
                    text_align = "center",
                    highlight = 'bufferline_offset',
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
            separator_style = "padded_slant",
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
