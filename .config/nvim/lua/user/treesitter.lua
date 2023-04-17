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
        indent = {
            enable = false,
            disable = {},
        },
        highlight = {
            enable = true, -- false will disable the whole extension
            disable = { "" }, -- list of language that will be disabled
            additional_vim_regex_highlighting = false,
        },
        ensure_installed = {
            "bash",
            "c",
            "cmake",
            "cpp",
            "go",
            "json",
            "lua",
            "python",
            "rust",
            "vim",
            "yaml"
        },
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
                enable = false,
                border = 'none',
                peek_definition_code = {
                    -- Offload this to lspsaga
                    -- ["<leader>lpf"] = "@function.outer",
                    -- ["<leader>lpc"] = "@class.outer",
                },
            }
        }
    }

    vim.opt["foldexpr"] = "nvim_treesitter#foldexpr()"

    -- Setup new symantic highlighting
    -- Reference: reddit.com/r/neovim/comments/12gvms4
    local links = {
        ['@lsp.type.namespace'] = '@namespace',
        ['@lsp.type.type'] = '@type',
        ['@lsp.type.class'] = '@type',
        ['@lsp.type.enum'] = '@type',
        ['@lsp.type.interface'] = '@type',
        ['@lsp.type.struct'] = '@structure',
        ['@lsp.type.parameter'] = '@parameter',
        ['@lsp.type.variable'] = '@variable',
        ['@lsp.type.property'] = '@property',
        ['@lsp.type.enumMember'] = '@constant',
        ['@lsp.type.function'] = '@function',
        ['@lsp.type.method'] = '@method',
        ['@lsp.type.macro'] = '@macro',
        ['@lsp.type.decorator'] = '@function',
    }

    for newgroup, oldgroup in pairs(links) do
        vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
    end
end

return M
