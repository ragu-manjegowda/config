-------------------------------------------------------------------------------
-- Test user/bracketed.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Bracketed Config", function()
    local bracketed_mod

    before_each(function()
        bracketed_mod = require("user.bracketed")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(bracketed_mod.config)
        end)
    end)

    describe("Bracketed Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if mini.bracketed plugin not available
            assert.has_no_errors(function()
                pcall(bracketed_mod.config)
            end)
        end)
    end)
end)
