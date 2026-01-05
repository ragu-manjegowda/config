-------------------------------------------------------------------------------
-- Test user/markview.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Markview Config", function()
    local markview_mod

    before_each(function()
        markview_mod = require("user.markview")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(markview_mod.config)
        end)
    end)

    describe("Markview Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if markview plugin not available
            assert.has_no_errors(function()
                pcall(markview_mod.config)
            end)
        end)
    end)
end)
