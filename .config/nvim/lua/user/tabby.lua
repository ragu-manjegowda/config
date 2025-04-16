-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local res, tabby

res, tabby = pcall(require, "tabby")
if not res then
    vim.notify("tabby not found", vim.log.levels.ERROR)
    return
end

local util = require("tabby.util")
local filename = require("tabby.module.filename")

local hl_tabline = util.extract_nvim_hl("TabLine")
local hl_tabline_sel = util.extract_nvim_hl("TabLineSel")
local hl_tabline_fill = util.extract_nvim_hl("TabLineFill")

local function gen_tab_name(tabid)
    local number = vim.api.nvim_tabpage_get_number(tabid)
    local focus = vim.api.nvim_tabpage_get_win(tabid)

    -- check if tab has more than one windows
    local length = #(util.tabpage_list_wins(tabid))
    length = length - 1
    local append = ""
    if length > 0 then
        append = " [" .. length .. "+] "
    end

    -- check if buffer is modified
    local buid = vim.api.nvim_win_get_buf(focus)
    local is_modified = vim.api.nvim_get_option_value("modified", { buf = buid })
    local modifiedIcon = is_modified and " " or ""

    -- return final output
    return " " .. number .. " " .. append .. filename.unique(focus)
        .. modifiedIcon
end

local tab_only = {
    hl = "TabLineFill",
    layout = "tab_only",
    head = {
        { "   ", hl = { fg = hl_tabline.fg, bg = hl_tabline.bg } },
        { "", hl = { fg = hl_tabline.bg, bg = hl_tabline_fill.bg } },
    },
    active_tab = {
        label = function(tabid)
            return {
                " " .. gen_tab_name(tabid) .. " ",
                hl = {
                    fg = hl_tabline_sel.fg,
                    bg = hl_tabline_sel.bg,
                    style = "bold",
                },
            }
        end,
        left_sep = {
            "",
            hl = { fg = hl_tabline_sel.bg, bg = hl_tabline_fill.bg },
        },
        right_sep = {
            "",
            hl = { fg = hl_tabline_sel.bg, bg = hl_tabline_fill.bg },
        },
    },
    inactive_tab = {
        label = function(tabid)
            return {
                " " .. gen_tab_name(tabid) .. " ",
                hl = { fg = hl_tabline.fg, bg = hl_tabline.bg, style = "bold" },
            }
        end,
        left_sep = {
            "",
            hl = { fg = hl_tabline.bg, bg = hl_tabline_fill.bg },
        },
        right_sep = {
            "",
            hl = { fg = hl_tabline.bg, bg = hl_tabline_fill.bg },
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
