-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.g.indent_blankline_filetype_exclude = {
            "lspinfo", "lazy", "checkhealth", "help", "man", "fugitive"
        }
end

function M.config()
    local res, indent_blankline = pcall(require, "indent_blankline")
    if not res then
        vim.notify("indentscope not found", vim.log.levels.ERROR)
        return
    end

    indent_blankline.setup({
        bufname_exclude = { "README.md" },
        char_list = { "|", "¦", "┆", "┊" },
        space_char_blankline = " ",
        show_trailing_blankline_indent = false,
        show_current_context = true,
        use_treesitter = true,
        treesitter_scope = true
    })

end

return M
