-------------------------------------------------------------------------------
-- Test user/dap.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("DAP Config", function()
    local dap_mod
    local dap

    before_each(function()
        dap = h.require_plugin("dap")
        dap_mod = h.require_user_module("user.dap")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(dap_mod.config)
            assert.is_function(dap_mod.define_mappings)
            assert.is_function(dap_mod.setup_cpp_adapters)
            assert.is_function(dap_mod.setup_go_adapters)
            assert.is_function(dap_mod.setup_python_adapters)
        end)
    end)

    describe("DAP Plugin Functions", function()
        it("dap should have functions that keymaps use", function()
            assert.is_function(dap.toggle_breakpoint)
            assert.is_function(dap.continue)
            assert.is_function(dap.step_into)
            assert.is_function(dap.step_over)
            assert.is_function(dap.step_out)
            assert.is_function(dap.terminate)
            assert.is_function(dap.restart)
            assert.is_function(dap.run_to_cursor)
            assert.is_function(dap.run_last)
            assert.is_function(dap.set_breakpoint)
            assert.is_function(dap.clear_breakpoints)
            assert.is_function(dap.set_exception_breakpoints)
        end)
    end)

    describe("DAP Keymaps (define_mappings())", function()
        before_each(function()
            dap_mod.define_mappings()
        end)

        it("<leader>dtb calls dap.toggle_breakpoint", function()
            h.assert_keymap_calls("<leader>dtb", "dap", "toggle_breakpoint")
        end)

        it("<leader>dce calls dap.continue", function()
            h.assert_keymap_calls("<leader>dce", "dap", "continue")
        end)

        it("<leader>si calls dap.step_into", function()
            h.assert_keymap_calls("<leader>si", "dap", "step_into")
        end)

        it("<leader>sn calls dap.step_over", function()
            h.assert_keymap_calls("<leader>sn", "dap", "step_over")
        end)

        it("<leader>so calls dap.step_out", function()
            h.assert_keymap_calls("<leader>so", "dap", "step_out")
        end)

        it("<leader>dte calls dap.terminate", function()
            h.assert_keymap_calls("<leader>dte", "dap", "terminate")
        end)

        it("<leader>drr calls dap.restart", function()
            h.assert_keymap_calls("<leader>drr", "dap", "restart")
        end)

        it("<leader>drc calls dap.run_to_cursor", function()
            h.assert_keymap_calls("<leader>drc", "dap", "run_to_cursor")
        end)

        it("<leader>drl calls dap.run_last", function()
            h.assert_keymap_calls("<leader>drl", "dap", "run_last")
        end)

        it("<leader>drb calls dap.clear_breakpoints", function()
            h.assert_keymap_calls("<leader>drb", "dap", "clear_breakpoints")
        end)

        it("<leader>dtui calls dapui.toggle", function()
            h.assert_keymap_calls("<leader>dtui", "dapui", "toggle")
        end)
    end)

    describe("DAP Setup (config())", function()
        it("should configure adapters without error", function()
            assert.has_no_errors(function()
                dap_mod.config()
            end)
        end)

        it("should configure cppdbg adapter", function()
            dap_mod.config()
            assert.is_not_nil(dap.adapters.cppdbg)
            assert.equals("executable", dap.adapters.cppdbg.type)
        end)

        it("should configure cpp configurations", function()
            dap_mod.config()
            assert.is_table(dap.configurations.cpp)
            assert.is_true(#dap.configurations.cpp > 0)
        end)

        it("should configure go adapter", function()
            dap_mod.config()
            assert.is_not_nil(dap.adapters.go)
        end)

        it("should configure python adapter", function()
            dap_mod.config()
            assert.is_not_nil(dap.adapters.python)
            assert.equals("executable", dap.adapters.python.type)
        end)
    end)
end)
