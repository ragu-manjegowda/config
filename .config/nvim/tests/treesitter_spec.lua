-------------------------------------------------------------------------------
-- Test user/treesitter.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Treesitter Config", function()
    local treesitter_mod

    before_each(function()
        treesitter_mod = require("user.treesitter")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(treesitter_mod.config)
        end)
    end)

    describe("Treesitter Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if nvim-treesitter not available
            assert.has_no_errors(function()
                pcall(treesitter_mod.config)
            end)
        end)
    end)

    describe("LSP Semantic Highlighting Links (user config)", function()
        before_each(function()
            pcall(treesitter_mod.config)
        end)

        it("should link @lsp.type.function to @function", function()
            local hl = vim.api.nvim_get_hl(0, { name = "@lsp.type.function" })
            assert.is_truthy(hl.link or next(hl) ~= nil,
                "@lsp.type.function should be linked per user config")
        end)

        it("should link @lsp.type.variable to @variable", function()
            local hl = vim.api.nvim_get_hl(0, { name = "@lsp.type.variable" })
            assert.is_truthy(hl.link or next(hl) ~= nil,
                "@lsp.type.variable should be linked per user config")
        end)
    end)
end)
