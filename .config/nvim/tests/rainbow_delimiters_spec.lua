-------------------------------------------------------------------------------
-- Test user/rainbow-delimiters.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("RainbowDelimiters Config", function()
    local rainbow_mod

    before_each(function()
        rainbow_mod = require("user.rainbow-delimiters")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(rainbow_mod.config)
        end)
    end)
end)
