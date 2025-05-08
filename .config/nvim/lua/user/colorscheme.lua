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

    vim.o.termguicolors = true

    local ok_status, solarized = pcall(require, "solarized")

    if not ok_status then
        return
    end

    local styles = {
        comments = { italic = true, bold = false },
        functions = { italic = true },
        variables = { italic = false },
    }

    solarized.setup {
        transparent = {
            enabled = true
        },
        styles = styles,
        plugins = {
            bufferline = false
        },
        variant = "spring",

        -- Add specific highlight groups
        on_highlights = function(colors, _)
            return {
                diffAdded               = { fg = colors.green },
                BlinkCmpKind            = { bold = true },
                BlinkCmpKindConstant    = { fg = colors.red },
                BlinkCmpKindEnum        = { fg = colors.orange },
                BlinkCmpKindField       = { fg = colors.violet },
                BlinkCmpKindMethod      = { fg = colors.green },
                BlinkCmpKindSnippet     = { fg = colors.orange },
                BlinkCmpLabelDeprecated = { fg = colors.red, strikethrough = true },
                BlinkCmpLabelMatch      = { fg = colors.green, bold = true },
                BlinkCmpMenuBorder      = { fg = colors.blue },
                BlinkCmpMenuSelection   = { fg = colors.base02, bg = colors.green },
                BlinkCmpSource          = { italic = true },
                BlinkCmpVariable        = { fg = colors.green },
                CursorWord              = { fg = colors.cyan, bold = true },
                FloatBorder             = { fg = colors.blue, bold = true },
                FloatTitle              = { fg = colors.red, bold = true },
                GitSignsAddLnInline     = { fg = colors.green, bold = true },
                GitSignsChangeLnInline  = { fg = colors.blue, bold = true },
                GitSignsDeleteLnInline  = { fg = colors.red, bold = true },
                LuaLineDiffAdd          = { fg = colors.green, bold = true },
                MarkviewHeading1        = { fg = colors.red, bold = true },
                MarkviewHeading2        = { fg = colors.green, bold = true },
                MarkviewHeading3        = { fg = colors.yellow, bold = true },
                MarkviewHeading4        = { fg = colors.orange, bold = true },
                MarkviewHeading5        = { fg = colors.cyan, bold = true },
                SmoothCursor            = { fg = colors.violet },
                SmoothCursorAqua        = { fg = colors.cyan },
                SmoothCursorBlue        = { fg = colors.blue },
                SmoothCursorGreen       = { fg = colors.green },
                SmoothCursorOrange      = { fg = colors.orange },
                SmoothCursorPurple      = { fg = colors.purple },
                SmoothCursorRed         = { fg = colors.red },
                SmoothCursorYellow      = { fg = colors.yellow },
                SpellBad                = { underline = true, strikethrough = false },
                TelescopeMatching       = { fg = colors.base02, bg = colors.cyan },
                TelescopeResultsComment = { fg = colors.purple, italic = true },
                TelescopeSelection      = { fg = colors.orange, bg = colors.base02, bold = true },
                Visual                  = { fg = colors.base02, bg = colors.yellow },
                WinBarNC                = { link = "Normal" },
                Winbar                  = { link = "Normal" }
            }
        end
    }

    -- Set colorscheme to solarized
    vim.cmd [[
        try
            " Use solarized
            colorscheme solarized
        catch /^Vim\%((\a\+)\)\=:E185/
            colorscheme default
        endtry
    ]]
end

return M
