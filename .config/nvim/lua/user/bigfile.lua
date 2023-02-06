-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.setup()
    local res, bigfile = pcall(require, "bigfile")
    if not res then
        vim.notify("bigfile not found", vim.log.levels.ERROR)
        return
    end

    bigfile.config({
        features = {
            "indent_blankline",
            "lsp",
            "treesitter",
            "syntax",
            "matchparen",
            "vimopts",
            "filetype",
        }
    })
end

return M
