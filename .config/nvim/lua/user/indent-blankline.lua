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
        bufname_exclude = { "README.md" },
        char_list = { "|", "¦", "┆", "┊" },
        exclude = {
            filetypes = {
                "lspinfo", "lazy", "checkhealth", "help", "man", "fugitive"
            }
        },
        indent = { tab_char = "|" },
        space_char_blankline = " ",
        show_trailing_blankline_indent = false,
        show_current_context = true,
        use_treesitter = true,
        treesitter_scope = true
    })
end

return M
