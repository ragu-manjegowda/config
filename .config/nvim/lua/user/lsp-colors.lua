local M = {}

function M.config()
    local res, lsp_colors = pcall(require, "lsp-colors")
    if not res then
        vim.notify("lsp-colors not found", vim.log.levels.ERROR)
        return
    end

    lsp_colors.setup({
        Error = "#db4b4b",
        Warning = "#e0af68",
        Information = "#0db9d7",
        Hint = "#10B981"
    })
end

return M
