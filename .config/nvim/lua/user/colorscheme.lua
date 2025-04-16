-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

---@class colorscheme
local M = {}

M.meta = {
    desc = "Set colorscheme",
    needs_setup = true,
}

function M.config()
    vim.cmd [[ set background=light ]]

    local ok_status, NeoSolarized = pcall(require, "NeoSolarized")

    if not ok_status then
        return
    end

    NeoSolarized.setup {
        transparent = false,
        terminal_colors = false,
        -- Add specific hightlight groups
        on_highlights = function(highlights, colors)
            highlights.BlinkCmpKind                 = { bold = true }
            highlights.BlinkCmpKindConstant         = { fg = colors.red }
            highlights.BlinkCmpKindEnum             = { fg = colors.orange }
            highlights.BlinkCmpKindField            = { fg = colors.violet }
            highlights.BlinkCmpKindMethod           = { fg = colors.green }
            highlights.BlinkCmpKindSnippet          = { fg = colors.orange }
            highlights.BlinkCmpLabelDeprecated      = { fg = colors.red, strikethrough = true }
            highlights.BlinkCmpLabelMatch           = { fg = colors.green, bold = true }
            highlights.BlinkCmpMenuBorder           = { fg = colors.blue }
            highlights.BlinkCmpMenuSelection        = { fg = colors.bg1, bg = colors.green }
            highlights.BlinkCmpSource               = { italic = true }
            highlights.BlinkCmpVariable             = { fg = colors.green }
            highlights.CursorWord                   = { fg = colors.aqua, bold = true }
            highlights.CustomRainbowDelimiterBlue   = { fg = colors.blue, bold = true }
            highlights.CustomRainbowDelimiterGreen  = { fg = colors.green, bold = true }
            highlights.CustomRainbowDelimiterOrange = { fg = colors.orange, bold = true }
            highlights.CustomRainbowDelimiterViolet = { fg = colors.violet, bold = true }
            highlights.CustomRainbowDelimiterYellow = { fg = colors.yellow, bold = true }
            highlights.FloatBorder                  = { fg = colors.blue, bold = true }
            highlights.FloatTitle                   = { fg = colors.red, bold = true }
            highlights.GitSignsAddLnInline          = { fg = colors.green, bold = true }
            highlights.GitSignsChangeLnInline       = { fg = colors.blue, bold = true }
            highlights.GitSignsDeleteLnInline       = { fg = colors.red, bold = true }
            highlights.LazyDimmed                   = { fg = colors.fg1, strikethrough = true }
            highlights.LuaLineDiffAdd               = { fg = colors.green, bold = true }
            highlights.LuaLineDiffChange            = { fg = colors.yellow, bold = true }
            highlights.LuaLineDiffDelete            = { fg = colors.red, bold = true }
            highlights.MarkviewHeading1             = { fg = colors.red, bold = true }
            highlights.MarkviewHeading2             = { fg = colors.green, bold = true }
            highlights.MarkviewHeading3             = { fg = colors.yellow, bold = true }
            highlights.MarkviewHeading4             = { fg = colors.orange, bold = true }
            highlights.MarkviewHeading5             = { fg = colors.aqua, bold = true }
            highlights.SmoothCursor                 = { fg = colors.violet, bg = colors.none }
            highlights.SmoothCursorAqua             = { fg = colors.aqua, bg = colors.none }
            highlights.SmoothCursorBlue             = { fg = colors.blue, bg = colors.none }
            highlights.SmoothCursorGreen            = { fg = colors.green, bg = colors.none }
            highlights.SmoothCursorOrange           = { fg = colors.orange, bg = colors.none }
            highlights.SmoothCursorPurple           = { fg = colors.purple, bg = colors.none }
            highlights.SmoothCursorRed              = { fg = colors.red, bg = colors.none }
            highlights.SmoothCursorYellow           = { fg = colors.yellow, bg = colors.none }
            highlights.TelescopeMatching            = { fg = colors.bg1, bg = colors.aqua }
            highlights.TelescopeSelection           = { bg = colors.orange, bold = true }
            highlights.Visual                       = { bg = colors.yellow, fg = colors.bg1 }
            highlights.WinBarNC                     = { link = "Normal" }
            highlights.Winbar                       = { link = "Normal" }
        end
    }

    -- Set colorscheme to NeoSolarized
    vim.cmd [[
        try
            " Use NeoSolarized
            colorscheme NeoSolarized
        catch /^Vim\%((\a\+)\)\=:E185/
            colorscheme default
        endtry
    ]]
end

return M
