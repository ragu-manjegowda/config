-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

M.config = function()
    local res, _ = pcall(require, "nvim-treesitter")
    if not res then
        vim.notify("nvim-treesitter not found", vim.log.levels.ERROR)
        return
    end

    require 'nvim-treesitter.configs'.setup {
        textobjects = {
            select = {
                enable = true,

                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,

                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                },
            },

            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    ["]m"] = "@function.outer",
                    ["]c"] = "@class.outer",
                },
                goto_next_end = {
                    ["]M"] = "@function.outer",
                    ["]C"] = "@class.outer",
                },
                goto_previous_start = {
                    ["[m"] = "@function.outer",
                    ["[c"] = "@class.outer",
                },
                goto_previous_end = {
                    ["[M"] = "@function.outer",
                    ["[C"] = "@class.outer",
                },
            },

            lsp_interop = {
                enable = true,
                border = 'none',
                peek_definition_code = {
                    -- Offload this to lspsaga
                    -- ["<leader>lpf"] = "@function.outer",
                    -- ["<leader>lpc"] = "@class.outer",
                },
            },
        },
    }
end

return M
