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

    -- Fix terminal colors: solarized.nvim has incorrect ANSI color mapping
    -- Matches ~/.config/alacritty/themes/solarized_{dark,light}.toml
    local function set_terminal_colors()
        -- Accent colors are the same for both light and dark themes
        -- Normal colors (0-7)
        vim.g.terminal_color_0 = "#073642"  -- normal.black
        vim.g.terminal_color_1 = "#dc322f"  -- normal.red
        vim.g.terminal_color_2 = "#859900"  -- normal.green
        vim.g.terminal_color_3 = "#b58900"  -- normal.yellow
        vim.g.terminal_color_4 = "#268bd2"  -- normal.blue
        vim.g.terminal_color_5 = "#d33682"  -- normal.magenta
        vim.g.terminal_color_6 = "#2aa198"  -- normal.cyan
        vim.g.terminal_color_7 = "#eee8d5"  -- normal.white
        -- Bright colors (8-15)
        vim.g.terminal_color_8 = "#002b36"  -- bright.black
        vim.g.terminal_color_9 = "#cb4b16"  -- bright.red (orange)
        vim.g.terminal_color_10 = "#586e75" -- bright.green
        vim.g.terminal_color_11 = "#657b83" -- bright.yellow
        vim.g.terminal_color_12 = "#839496" -- bright.blue
        vim.g.terminal_color_13 = "#6c71c4" -- bright.magenta (violet)
        vim.g.terminal_color_14 = "#93a1a1" -- bright.cyan
        vim.g.terminal_color_15 = "#fdf6e3" -- bright.white
    end

    -- Set terminal colors now
    set_terminal_colors()
end

return M
