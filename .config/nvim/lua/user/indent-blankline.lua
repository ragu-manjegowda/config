-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, indent_blankline = pcall(require, "ibl")
    if not res then
        vim.notify("indent-blankline not found", vim.log.levels.ERROR)
        return
    end

    indent_blankline.setup({
        exclude = {
            filetypes = {
                "lspinfo", "lazy", "checkhealth", "help", "man", "fugitive"
            },
            buftypes = { "markdown" },
        },
        indent = { tab_char = "|" }
    })
end

return M
