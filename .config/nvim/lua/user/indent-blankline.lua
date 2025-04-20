-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

vim.g.u_indent_blankline_enabled = true

function M.config()
    local res, indent_blankline = pcall(require, "ibl")
    if not res then
        vim.notify("indent-blankline not found", vim.log.levels.ERROR)
        return
    end

    indent_blankline.setup({
        exclude = {
            filetypes = {
                "lspinfo", "lazy", "checkhealth", "help", "man", "fugitive",
                "text", "markdown", "BigFile"
            },
            buftypes = { "markdown" },
        },
        indent = { tab_char = "|" }
    })

    vim.api.nvim_create_user_command(
        "ToggleIndentBlankLine",
        function()
            if vim.g.u_indent_blankline_enabled then
                indent_blankline.update { enabled = false }
                vim.g.u_indent_blankline_enabled = false
            else
                indent_blankline.update { enabled = true }
                vim.g.u_indent_blankline_enabled = true
            end
        end, {}
    )
end

return M
