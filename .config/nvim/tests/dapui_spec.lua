-------------------------------------------------------------------------------
-- Test user/dapui.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("DAPUI Config", function()
    local dapui_mod
    local dapui
    local dap

    before_each(function()
        dapui = h.require_plugin("dapui")
        dap = h.require_plugin("dap")
        dapui_mod = h.require_user_module("user.dapui")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(dapui_mod.config)
        end)
    end)

    describe("DAPUI Plugin Functions", function()
        it("dapui should have functions that keymaps use", function()
            assert.is_function(dapui.eval)
            assert.is_function(dapui.open)
            assert.is_function(dapui.close)
            assert.is_function(dapui.toggle)
        end)
    end)

    describe("DAPUI Keymaps (config())", function()
        before_each(function()
            dapui_mod.config()
        end)

        it("<leader>dex (normal) calls dapui.eval", function()
            h.assert_keymap_calls("<leader>dex", "dapui", "eval", "n")
        end)

        it("<leader>dex (visual) calls dapui.eval", function()
            h.assert_keymap_calls("<leader>dex", "dapui", "eval", "v")
        end)
    end)

    describe("DAPUI Setup (config())", function()
        before_each(function()
            dapui_mod.config()
        end)

        it("should define DapBreakpoint sign", function()
            local signs = vim.fn.sign_getdefined("DapBreakpoint")
            assert.is_true(#signs > 0)
            assert.is_truthy(string.match(vim.trim(signs[1].text), ""))
        end)

        it("should define DapBreakpointCondition sign", function()
            local signs = vim.fn.sign_getdefined("DapBreakpointCondition")
            assert.is_true(#signs > 0)
            assert.is_truthy(string.match(vim.trim(signs[1].text), ""))
        end)

        it("should define DapLogPoint sign", function()
            local signs = vim.fn.sign_getdefined("DapLogPoint")
            assert.is_true(#signs > 0)
            assert.is_truthy(string.match(vim.trim(signs[1].text), ""))
        end)

        it("should define DapStopped sign", function()
            local signs = vim.fn.sign_getdefined("DapStopped")
            assert.is_true(#signs > 0)
            assert.is_truthy(string.match(vim.trim(signs[1].text), "→"))
        end)

        it("should configure DAP listeners for auto open/close", function()
            assert.is_function(dap.listeners.after.event_initialized["dapui_config"])
            assert.is_function(dap.listeners.before.event_terminated["dapui_config"])
            assert.is_function(dap.listeners.before.event_exited["dapui_config"])
            assert.is_function(dap.listeners.before.disconnect["dapui_config"])
        end)
    end)
end)
