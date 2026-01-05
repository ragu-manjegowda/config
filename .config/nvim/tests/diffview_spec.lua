-------------------------------------------------------------------------------
-- Test user/diffview.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Diffview Config", function()
    local diffview_mod

    before_each(function()
        h.require_plugin("diffview")
        diffview_mod = h.require_user_module("user.diffview")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(diffview_mod.config)
        end)
    end)

    describe("Diffview Keymaps (config())", function()
        before_each(function()
            diffview_mod.config()
        end)

        it("<leader>gstd opens DiffviewOpen", function()
            h.assert_keymap_exists("<leader>gstd", "n")
            local map = vim.fn.maparg("<leader>gstd", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "DiffviewOpen"))
        end)
    end)

    describe("Diffview Setup (config())", function()
        it("should configure diffview without error", function()
            assert.has_no_errors(function()
                diffview_mod.config()
            end)
        end)
    end)
end)
