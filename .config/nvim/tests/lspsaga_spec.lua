-------------------------------------------------------------------------------
-- Test user/lspsaga.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("LSPSaga Config", function()
    local lspsaga_mod

    before_each(function()
        h.require_plugin("lspsaga")
        lspsaga_mod = h.require_user_module("user.lspsaga")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(lspsaga_mod.config)
        end)
    end)

    describe("LSPSaga Keymaps (config())", function()
        before_each(function()
            lspsaga_mod.config()
        end)

        it("[d runs Lspsaga diagnostic_jump_prev", function()
            h.assert_keymap_exists("[d", "n")
            local map = vim.fn.maparg("[d", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga diagnostic_jump_prev"))
        end)

        it("]d runs Lspsaga diagnostic_jump_next", function()
            h.assert_keymap_exists("]d", "n")
            local map = vim.fn.maparg("]d", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga diagnostic_jump_next"))
        end)

        it("[e calls lspsaga.diagnostic:goto_prev with ERROR severity", function()
            h.assert_keymap_exists("[e", "n")
            local map = vim.fn.maparg("[e", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "lspsaga"))
            assert.is_truthy(string.match(map.rhs, "goto_prev"))
            assert.is_truthy(string.match(map.rhs, "ERROR"))
        end)

        it("]e calls lspsaga.diagnostic:goto_next with ERROR severity", function()
            h.assert_keymap_exists("]e", "n")
            local map = vim.fn.maparg("]e", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "lspsaga"))
            assert.is_truthy(string.match(map.rhs, "goto_next"))
            assert.is_truthy(string.match(map.rhs, "ERROR"))
        end)

        it("<leader>ep runs Lspsaga show_line_diagnostics", function()
            h.assert_keymap_exists("<leader>ep", "n")
            local map = vim.fn.maparg("<leader>ep", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga show_line_diagnostics"))
        end)

        it("<leader>eP runs Lspsaga show_cursor_diagnostics", function()
            h.assert_keymap_exists("<leader>eP", "n")
            local map = vim.fn.maparg("<leader>eP", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga show_cursor_diagnostics"))
        end)

        it("<leader>lca runs Lspsaga code_action (normal)", function()
            h.assert_keymap_exists("<leader>lca", "n")
            local map = vim.fn.maparg("<leader>lca", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga code_action"))
        end)

        it("<leader>lca runs Lspsaga code_action (visual)", function()
            h.assert_keymap_exists("<leader>lca", "v")
            local map = vim.fn.maparg("<leader>lca", "v", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga code_action"))
        end)

        it("<leader>ld runs Lspsaga goto_definition", function()
            h.assert_keymap_exists("<leader>ld", "n")
            local map = vim.fn.maparg("<leader>ld", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga goto_definition"))
        end)

        it("<leader>lco runs Lspsaga outline", function()
            h.assert_keymap_exists("<leader>lco", "n")
            local map = vim.fn.maparg("<leader>lco", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga outline"))
        end)

        it("<leader>lpf runs Lspsaga peek_definition", function()
            h.assert_keymap_exists("<leader>lpf", "n")
            local map = vim.fn.maparg("<leader>lpf", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga peek_definition"))
        end)

        it("<leader>lr runs Lspsaga rename", function()
            h.assert_keymap_exists("<leader>lr", "n")
            local map = vim.fn.maparg("<leader>lr", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga rename"))
        end)

        it("<leader>lrp runs Lspsaga rename ++project", function()
            h.assert_keymap_exists("<leader>lrp", "n")
            local map = vim.fn.maparg("<leader>lrp", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga rename"))
            assert.is_truthy(string.match(map.rhs, "project"))
        end)

        it("<leader>lsy runs Lspsaga finder", function()
            h.assert_keymap_exists("<leader>lsy", "n")
            local map = vim.fn.maparg("<leader>lsy", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Lspsaga finder"))
        end)
    end)
end)
