-------------------------------------------------------------------------------
-- Test user/flatten.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Flatten Config", function()
    local flatten_mod

    before_each(function()
        flatten_mod = require("user.flatten")
    end)

    describe("Module Interface", function()
        it("should expose opts function", function()
            assert.is_function(flatten_mod.opts)
        end)
    end)

    describe("opts()", function()
        it("should return a table", function()
            local opts = flatten_mod.opts()
            assert.is_table(opts)
        end)

        it("should configure window.open to tab (user config)", function()
            local opts = flatten_mod.opts()
            assert.is_table(opts.window)
            assert.equals("tab", opts.window.open,
                "window.open should be 'tab' per user config")
        end)
    end)
end)
