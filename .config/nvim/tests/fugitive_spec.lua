-------------------------------------------------------------------------------
-- Test user/fugitive.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Fugitive Config", function()
    local fugitive_mod

    before_each(function()
        fugitive_mod = h.require_user_module("user.fugitive")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(fugitive_mod.config)
        end)
    end)

    describe("Fugitive Keymaps (config())", function()
        before_each(function()
            fugitive_mod.config()
        end)

        it("<leader>gfa runs Git fetch --all --prune", function()
            h.assert_keymap_exists("<leader>gfa", "n")
            local map = vim.fn.maparg("<leader>gfa", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Git fetch"))
        end)

        it("<leader>glog runs GcLog", function()
            h.assert_keymap_exists("<leader>glog", "n")
            local map = vim.fn.maparg("<leader>glog", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "GcLog"))
        end)

        it("<leader>glogf runs Git log for current file", function()
            h.assert_keymap_exists("<leader>glogf", "n")
            local map = vim.fn.maparg("<leader>glogf", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Git log"))
        end)

        it("<leader>gpulla runs Git pull --rebase --autostash", function()
            h.assert_keymap_exists("<leader>gpulla", "n")
            local map = vim.fn.maparg("<leader>gpulla", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Git pull"))
        end)

        it("<leader>gst opens Git status in tab", function()
            h.assert_keymap_exists("<leader>gst", "n")
            local map = vim.fn.maparg("<leader>gst", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "tab G"))
        end)

        it("<leader>gpf runs diffget //2", function()
            h.assert_keymap_exists("<leader>gpf", "n")
            local map = vim.fn.maparg("<leader>gpf", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "diffget //2"))
        end)

        it("<leader>gpj runs diffget //3", function()
            h.assert_keymap_exists("<leader>gpj", "n")
            local map = vim.fn.maparg("<leader>gpj", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "diffget //3"))
        end)
    end)
end)
