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
        auto_install = true,
        ensure_installed = {
            "bash",
            "c",
            "cmake",
            "cpp",
            "css",
            "diff",
            "dockerfile",
            "git_config",
            "gitcommit",
            "go",
            "gomod",
            "gosum",
            "html",
            "ini",
            "javascript",
            "json",
            "lua",
            "markdown",
            "markdown_inline",
            "muttrc",
            "python",
            "query",
            "regex",
            "rust",
            "starlark",
            "tmux",
            "toml",
            "usd",
            "vim",
            "vimdoc",
            "yaml"
        },
        highlight = {
            enable = true,    -- false will disable the whole extension
            disable = { "" }, -- list of language that will be disabled
            additional_vim_regex_highlighting = false,
        },
        ignore_install = {},
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<M-/>",
                node_incremental = "<M-/>",
                scope_incremental = false,
                node_decremental = "<bs>",
            },
        },
        indent = {
            enable = false,
            disable = {},
        },
        modules = {},
        sync_install = false,
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
    -- vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    -- vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"

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
