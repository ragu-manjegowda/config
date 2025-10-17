-- Test ACTUAL BEHAVIOR of LSP
describe("LSP Behavior", function()
    before_each(function()
        local ok, mod = pcall(require, "user.lspconfig")
        if ok then
            if mod.setup_diagnostics then pcall(mod.setup_diagnostics) end
            if mod.setup_inlayHints then pcall(mod.setup_inlayHints) end
        end
    end)

    describe("Diagnostic Configuration", function()
        it("should have virtual_lines disabled by default", function()
            local config = vim.diagnostic.config()
            assert.is_false(config.virtual_lines or false, "virtual_lines should be disabled by default")
        end)

        it("virtual_lines toggle should work", function()
            local initial = vim.diagnostic.config().virtual_lines or false
            
            -- Toggle
            vim.diagnostic.config({ virtual_lines = not initial })
            local after_toggle = vim.diagnostic.config().virtual_lines or false
            
            assert.is_not_equals(initial, after_toggle, "virtual_lines should toggle")
            
            -- Toggle back
            vim.diagnostic.config({ virtual_lines = initial })
        end)

        it("should have diagnostic signs configured", function()
            local config = vim.diagnostic.config()
            assert.is_table(config.signs)
        end)

        it("should have severity levels defined", function()
            assert.is_number(vim.diagnostic.severity.ERROR)
            assert.is_number(vim.diagnostic.severity.WARN)
            assert.is_number(vim.diagnostic.severity.INFO)
            assert.is_number(vim.diagnostic.severity.HINT)
        end)
    end)

    describe("LSP Capabilities", function()
        it("should have default capabilities", function()
            local lspconfig_mod = require("user.lspconfig")
            assert.is_function(lspconfig_mod.get_default_config)
            
            local config = lspconfig_mod.get_default_config()
            assert.is_table(config)
            assert.is_table(config.capabilities)
        end)

        it("should have server setup functions", function()
            local lspconfig_mod = require("user.lspconfig")
            assert.is_function(lspconfig_mod.gopls_setup)
            assert.is_function(lspconfig_mod.clangd_setup)
            assert.is_function(lspconfig_mod.markdown_setup)
        end)
    end)

    describe("LSP Autocommands", function()
        it("should have LspAttach autocommand", function()
            local autocmds = vim.api.nvim_get_autocmds({
                group = "lsp attach",
                event = "LspAttach"
            })
            assert.is_true(#autocmds > 0, "LspAttach autocmd should exist")
        end)
    end)

    describe("Completion Kind Icons", function()
        it("should configure CompletionItemKind", function()
            local lspconfig_mod = require("user.lspconfig")
            assert.is_function(lspconfig_mod.setup_completionKind)
            
            assert.has_no_errors(function()
                lspconfig_mod.setup_completionKind()
            end)
        end)
    end)
end)
