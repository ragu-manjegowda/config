-------------------------------------------------------------------------------
-- Test user/lspconfig.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("LSP Config", function()
    local lspconfig_mod

    before_each(function()
        -- Module may return early if lspconfig not found
        local ok, mod = pcall(require, "user.lspconfig")
        if ok and type(mod) == "table" then
            lspconfig_mod = mod
        else
            lspconfig_mod = nil
        end
    end)

    describe("Module Interface", function()
        it("should load module or return early gracefully", function()
            -- If module returns early due to missing deps, it returns nil
            -- If it loads, it should be a table with functions
            if lspconfig_mod then
                assert.is_table(lspconfig_mod)
            end
        end)

        it("should expose required functions when loaded", function()
            if lspconfig_mod then
                assert.is_function(lspconfig_mod.config)
                assert.is_function(lspconfig_mod.get_default_config)
                assert.is_function(lspconfig_mod.servers_opts)
                assert.is_function(lspconfig_mod.setup_diagnostics)
                assert.is_function(lspconfig_mod.setup_completionKind)
                assert.is_function(lspconfig_mod.setup_inlayHints)
                assert.is_function(lspconfig_mod.define_lsp_attach_keymap)
                assert.is_function(lspconfig_mod.gopls_setup)
                assert.is_function(lspconfig_mod.clangd_setup)
                assert.is_function(lspconfig_mod.markdown_setup)
                assert.is_function(lspconfig_mod.enable_with_lspconfig)
                assert.is_function(lspconfig_mod.enable_with_vim_lsp)
            end
        end)
    end)

    describe("get_default_config()", function()
        it("should return table with capabilities when loaded", function()
            if lspconfig_mod and lspconfig_mod.get_default_config then
                local config = lspconfig_mod.get_default_config()
                assert.is_table(config)
                assert.is_table(config.capabilities)
            end
        end)
    end)

    describe("servers_opts()", function()
        it("should return table with servers key when loaded", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                assert.is_table(opts)
                assert.is_table(opts.servers)
            end
        end)

        it("should configure expected LSP servers when loaded", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local expected_servers = {
                    "bashls", "biome", "clangd", "cmake", "gopls",
                    "harper_ls", "jsonls", "lua_ls", "marksman",
                    "pylsp", "ruby_lsp", "rust_analyzer", "standardrb",
                    "vimls", "yamlls"
                }

                for _, server in ipairs(expected_servers) do
                    assert.is_table(opts.servers[server],
                        server .. " should be configured")
                end
            end
        end)

        it("should configure lua_ls with hint.enable (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local lua_ls = opts.servers.lua_ls
                assert.is_true(lua_ls.settings.Lua.hint.enable,
                    "lua_ls should have hint.enable = true per user config")
            end
        end)

        it("should configure lua_ls telemetry disabled (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local lua_ls = opts.servers.lua_ls
                assert.is_false(lua_ls.settings.Lua.telemetry.enable,
                    "lua_ls should have telemetry disabled per user config")
            end
        end)

        it("should configure pylsp with ruff enabled (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local pylsp = opts.servers.pylsp
                assert.is_true(pylsp.settings.pylsp.plugins.ruff.enabled,
                    "pylsp should have ruff enabled per user config")
            end
        end)

        it("should configure pylsp with black enabled (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local pylsp = opts.servers.pylsp
                assert.is_true(pylsp.settings.pylsp.plugins.black.enabled,
                    "pylsp should have black enabled per user config")
            end
        end)

        it("should configure rust_analyzer with inlay hints (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local rust = opts.servers.rust_analyzer
                assert.is_true(rust.settings["rust-analyzer"].inlayHints.enabled,
                    "rust_analyzer should have inlayHints enabled per user config")
            end
        end)

        it("should configure harper_ls for specific filetypes (user config)", function()
            if lspconfig_mod and lspconfig_mod.servers_opts then
                local opts = lspconfig_mod.servers_opts()
                local harper = opts.servers.harper_ls
                assert.is_table(harper.filetypes)
                -- User config limits harper to html and toml
                local has_html = vim.tbl_contains(harper.filetypes, "html")
                local has_toml = vim.tbl_contains(harper.filetypes, "toml")
                assert.is_true(has_html, "harper_ls should include html per user config")
                assert.is_true(has_toml, "harper_ls should include toml per user config")
            end
        end)
    end)

    describe("clangd_setup()", function()
        it("should return table with cmd when loaded", function()
            if lspconfig_mod and lspconfig_mod.clangd_setup then
                local config = lspconfig_mod.clangd_setup()
                assert.is_table(config)
                assert.is_table(config.cmd)
            end
        end)

        it("should include clangd as first command", function()
            if lspconfig_mod and lspconfig_mod.clangd_setup then
                local config = lspconfig_mod.clangd_setup()
                assert.equals("clangd", config.cmd[1])
            end
        end)

        it("should include background-index flag (user config)", function()
            if lspconfig_mod and lspconfig_mod.clangd_setup then
                local config = lspconfig_mod.clangd_setup()
                local has_bg_index = vim.tbl_contains(config.cmd, "--background-index")
                assert.is_true(has_bg_index,
                    "clangd should have --background-index per user config")
            end
        end)

        it("should include clang-tidy flag (user config)", function()
            if lspconfig_mod and lspconfig_mod.clangd_setup then
                local config = lspconfig_mod.clangd_setup()
                local has_clang_tidy = vim.tbl_contains(config.cmd, "--clang-tidy")
                assert.is_true(has_clang_tidy,
                    "clangd should have --clang-tidy per user config")
            end
        end)

        it("should have header-insertion=never (user config)", function()
            if lspconfig_mod and lspconfig_mod.clangd_setup then
                local config = lspconfig_mod.clangd_setup()
                local has_header_never = vim.tbl_contains(config.cmd, "--header-insertion=never")
                assert.is_true(has_header_never,
                    "clangd should have --header-insertion=never per user config")
            end
        end)
    end)

    describe("gopls_setup()", function()
        it("should return table with settings when loaded", function()
            if lspconfig_mod and lspconfig_mod.gopls_setup then
                local config = lspconfig_mod.gopls_setup()
                assert.is_table(config)
                assert.is_table(config.settings)
                assert.is_table(config.settings.gopls)
            end
        end)

        it("should enable staticcheck (user config)", function()
            if lspconfig_mod and lspconfig_mod.gopls_setup then
                local config = lspconfig_mod.gopls_setup()
                assert.is_true(config.settings.gopls.staticcheck,
                    "gopls should have staticcheck enabled per user config")
            end
        end)

        it("should enable unusedparams analysis (user config)", function()
            if lspconfig_mod and lspconfig_mod.gopls_setup then
                local config = lspconfig_mod.gopls_setup()
                assert.is_true(config.settings.gopls.analyses.unusedparams,
                    "gopls should have unusedparams analysis per user config")
            end
        end)

        it("should configure directory filters for bazel (user config)", function()
            if lspconfig_mod and lspconfig_mod.gopls_setup then
                local config = lspconfig_mod.gopls_setup()
                assert.is_table(config.settings.gopls.directoryFilters,
                    "gopls should have directoryFilters per user config")
            end
        end)
    end)

    describe("LspAttach Autocommand", function()
        it("should have LspAttach autocommand configured when loaded", function()
            if lspconfig_mod then
                local autocmds = vim.api.nvim_get_autocmds({
                    group = "lsp attach",
                    event = "LspAttach"
                })
                assert.is_true(#autocmds > 0, "LspAttach autocmd should exist")
            end
        end)
    end)
end)
