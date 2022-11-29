local M = {}

function M.config()

    require('mason-tool-installer').setup {

        -- a list of all tools you want to ensure are installed upon
        -- start; they should be the names Mason uses for each tool
        ensure_installed = {
            'bash-language-server',
            'clangd',
            'cpptools', -- c/cpp/rust dubugging
            'cmake-language-server',
            'delve', -- golang debugging
            'gopls',
            'lua-language-server',
            'pyright',
            'rust-analyzer',
            'vim-language-server',
        },

        -- automatically install / update on startup. If set to false nothing
        -- will happen on startup. You can use :MasonToolsInstall or
        -- :MasonToolsUpdate to install tools and check for updates.
        -- Default: true
        run_on_start = false,
    }

end

return M
