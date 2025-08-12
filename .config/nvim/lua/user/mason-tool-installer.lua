-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, mason_tool_installer = pcall(require, "mason-tool-installer")
    if not res then
        vim.notify("mason-tool-installer not found", vim.log.levels.ERROR)
        return
    end

    mason_tool_installer.setup {

        -- a list of all tools you want to ensure are installed upon
        -- start; they should be the names Mason uses for each tool
        ensure_installed = {
            "bash-language-server",
            "biome",                           -- typescript formatting/linting
            "bzl",                             -- starlark
            "clangd",
            "cmake-language-server",
            "cpptools",                        -- c/cpp/rust debugging
            "debugpy",                         -- python debugging
            "delve",                           -- golang debugging
            "gopls",
            "harper-ls",
            "json-lsp",
            "lua-language-server",
            "marksman",
            "ruby-lsp",
            "rust-analyzer",
            "shellcheck", -- sh linting
            "standardrb", -- ruby linting / formatting
            "vim-language-server",
            "yaml-language-server"
        },

        -- automatically install / update on startup. If set to false nothing
        -- will happen on startup. You can use :MasonToolsInstall or
        -- :MasonToolsUpdate to install tools and check for updates.
        -- Default: true
        run_on_start = false,
    }
end

return M
