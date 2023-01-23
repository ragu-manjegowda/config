-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, smoothcursor = pcall(require, "smoothcursor")
    if not res then
        vim.notify("smoothcursor not found", vim.log.levels.ERROR)
        return
    end

    smoothcursor.setup({
        fancy = {
            enable = true,
        },
        disable_float_win = true,
        threshold = 10,
        disabled_filetypes = { "TelescopePrompt", "NvimTree" }
    })
end

return M
