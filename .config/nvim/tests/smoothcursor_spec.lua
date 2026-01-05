-------------------------------------------------------------------------------
-- Test user/smoothcursor.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("SmoothCursor Config", function()
    local smoothcursor_mod

    before_each(function()
        smoothcursor_mod = require("user.smoothcursor")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(smoothcursor_mod.config)
        end)
    end)
end)
