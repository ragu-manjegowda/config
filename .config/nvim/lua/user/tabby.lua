local tabby = require('tabby')
local util = require('tabby.util')
local filename = require('tabby.filename')

local hl_normal = util.extract_nvim_hl('Normal')
local hl_tabline = util.extract_nvim_hl('TabLine')
local hl_tabline_sel = util.extract_nvim_hl('TabLineSel')
local hl_tabline_fill = util.extract_nvim_hl('TabLineFill')

local function gen_tab_name(tabid)
    local number = vim.api.nvim_tabpage_get_number(tabid)
    local focus = vim.api.nvim_tabpage_get_win(tabid)
    local length = #(util.tabpage_list_wins(tabid))
    length = length - 1
    local append = ''
    if length > 0 then
        append = ' [' .. length .. '+]'
    end
    return  ' ' .. number .. ' ' .. append .. filename.unique(focus)
end

local tab_only = {
    hl = 'TabLineFill',
    layout = 'tab_only',
    head = {
        { '   ', hl = { fg = hl_tabline.fg, bg = hl_tabline.bg } },
        { '', hl = { fg = hl_tabline.bg, bg = hl_tabline_fill.bg } },
    },
    active_tab = {
        label = function(tabid)
            return {
                ' ' .. gen_tab_name(tabid) .. ' ',
                hl = {
                  fg = hl_tabline_sel.fg,
                  bg = hl_tabline_sel.bg,
                  style = 'bold',
                },
            }
        end,
        left_sep = {
            '',
            hl = { fg = hl_tabline_sel.bg, bg = hl_tabline_fill.bg },
        },
        right_sep = {
            '',
            hl = { fg = hl_tabline_sel.bg, bg = hl_tabline_fill.bg },
        },
    },
    inactive_tab = {
        label = function(tabid)
            return {
                ' ' .. gen_tab_name(tabid) .. ' ',
                hl = { fg = hl_normal.fg, bg = hl_normal.bg, style = 'bold' },
            }
        end,
        left_sep = {
            '',
            hl = { fg = hl_normal.bg, bg = hl_tabline_fill.bg },
        },
        right_sep = {
            '',
            hl = { fg = hl_normal.bg, bg = hl_tabline_fill.bg },
        },
    },
    -- tail = {
    --   { '', hl = { fg = hl_tabline.bg, bg = hl_tabline_fill.bg } },
    --   { '  ', hl = { fg = hl_tabline.fg, bg = hl_tabline.bg } },
    -- },
}

local M = {}

function M.config()
    tabby.setup({ tabline = tab_only })
end

return M

