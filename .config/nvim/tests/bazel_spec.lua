-------------------------------------------------------------------------------
-- Test user/bazel.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Bazel Config", function()
    local bazel_mod

    before_each(function()
        bazel_mod = require("user.bazel")
    end)

    describe("Module Interface", function()
        it("should expose before function", function()
            assert.is_function(bazel_mod.before)
        end)
    end)

    describe("Bazel Setup (before())", function()
        before_each(function()
            -- Reset globals
            vim.g.bazel_config = nil
            vim.g.bazel_cmd = nil
            pcall(bazel_mod.before)
        end)

        it("should set bazel_config to empty string if nil (user config)", function()
            assert.equals("", vim.g.bazel_config,
                "bazel_config should default to empty string per user config")
        end)

        it("should set bazel_cmd to dazel.py (user config)", function()
            assert.equals("dazel.py", vim.g.bazel_cmd,
                "bazel_cmd should be 'dazel.py' per user config")
        end)
    end)
end)
