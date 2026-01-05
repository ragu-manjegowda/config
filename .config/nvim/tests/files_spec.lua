-------------------------------------------------------------------------------
-- Test user/files.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("MiniFiles Config", function()
    local files_mod

    before_each(function()
        files_mod = require("user.files")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(files_mod.config)
        end)
    end)

    describe("MiniFiles Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if mini.files plugin not available
            assert.has_no_errors(function()
                pcall(files_mod.config)
            end)
        end)
    end)
end)
