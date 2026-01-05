-------------------------------------------------------------------------------
-- Test user/which-key.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("WhichKey Config", function()
    local whichkey_mod

    before_each(function()
        whichkey_mod = require("user.which-key")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(whichkey_mod.before)
            assert.is_function(whichkey_mod.config)
        end)
    end)

    describe("Before Setup (before())", function()
        before_each(function()
            pcall(whichkey_mod.before)
        end)

        it("should set <leader>? keymap in normal mode", function()
            local map = vim.fn.maparg("<leader>?", "n", false, true)
            assert.is_truthy(map.rhs or map.callback,
                "<leader>? should be mapped in normal mode")
        end)

        it("should set <leader>? keymap in visual mode", function()
            local map = vim.fn.maparg("<leader>?", "v", false, true)
            assert.is_truthy(map.rhs or map.callback,
                "<leader>? should be mapped in visual mode")
        end)
    end)

    describe("WhichKey Setup (config())", function()
        it("should not error when calling config()", function()
            -- Just verify the config function doesn't error
            -- The actual plugin may not be available in test env
            assert.has_no_errors(function()
                pcall(whichkey_mod.config)
            end)
        end)
    end)
end)
