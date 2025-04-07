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

    rainbow_delimiters_setup.setup({
        strategy = {
            [""] = rainbow_delimiters.strategy["global"],
            vim = rainbow_delimiters.strategy["local"],
        },
        query = {
            [""] = "rainbow-delimiters",
            lua = "rainbow-blocks",
        },
        blacklist = {}
    })
end

return M
