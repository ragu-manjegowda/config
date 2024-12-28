-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, rainbow_delimiters = pcall(require, "rainbow-delimiters")
    if not res then
        vim.notify("rainbow-delimiters not found", vim.log.levels.ERROR)
        return
    end

    local rainbow_delimiters_setup
    res, rainbow_delimiters_setup = pcall(require, "rainbow-delimiters.setup")
    if not res then
        vim.notify("rainbow-delimiters.setup not found", vim.log.levels.ERROR)
        return
    end

    -- Define the list of pairs (highlight group and associated color)
    local highlight_groups = {
        CustomRainbowDelimiterBlue = vim.g.gui_blue,
        CustomRainbowDelimiterYellow = vim.g.gui_yellow,
        CustomRainbowDelimiterOrange = vim.g.gui_orange,
        CustomRainbowDelimiterGreen = vim.g.gui_green,
        CustomRainbowDelimiterViolet = vim.g.gui_violet,
        CustomRainbowDelimiterCyan = vim.g.gui_cyan
    }

    -- Iterate through the list and set each highlight group
    for group_name, color in pairs(highlight_groups) do
        vim.api.nvim_set_hl(0, group_name, { fg = color })
    end

    rainbow_delimiters_setup.setup({
        strategy = {
            [""] = rainbow_delimiters.strategy["global"],
            vim = rainbow_delimiters.strategy["local"],
        },
        query = {
            [""] = "rainbow-delimiters",
            lua = "rainbow-blocks",
        },
        highlight = {
            "CustomRainbowDelimiterOrange",
            "CustomRainbowDelimiterYellow",
            "CustomRainbowDelimiterGreen",
            "CustomRainbowDelimiterBlue",
            "CustomRainbowDelimiterViolet",
            "CustomRainbowDelimiterCyan",
        },
        blacklist = {}
    })
end

return M
