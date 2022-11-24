local M = {}

M.config = function()
    require'nvim-treesitter.configs'.setup {
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
            "c",
            "cpp",
            "go",
            "lua",
            "python",
            "rust"
        },
    }
end

return M
