local M = {}

M.config = function()
    local res, _ = pcall(require, "nvim-treesitter")
    if not res then
        vim.notify("nvim-treesitter not found", vim.log.levels.ERROR)
        return
    end

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
            "rust",
            "yaml"
        },
    }
end

return M
