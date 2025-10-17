-- Test ACTUAL BEHAVIOR of DAP (Debug Adapter Protocol)
describe("DAP Behavior", function()
    before_each(function()
        local ok, mod = pcall(require, "user.dap")
        if ok and mod.config then
            pcall(mod.config)
        end
    end)

    describe("DAP Module Loading", function()
        it("should load DAP without errors", function()
            assert.has_no_errors(function()
                require("dap")
            end)
        end)

        it("should have breakpoints API available", function()
            local dap = require("dap")
            assert.is_function(dap.set_breakpoint)
            assert.is_function(dap.toggle_breakpoint)
            assert.is_function(dap.continue)
        end)

        it("should have stepping functions available", function()
            local dap = require("dap")
            assert.is_function(dap.step_into)
            assert.is_function(dap.step_over)
            assert.is_function(dap.step_out)
        end)
    end)

    describe("Adapter Configuration", function()
        it("should have Python adapter configured", function()
            local dap = require("dap")
            -- After config is called, adapters should be set up
            assert.is_truthy(dap.adapters.python or dap.configurations.python, 
                "Python DAP adapter should exist")
        end)

        it("should have C++ adapter configured", function()
            local dap = require("dap")
            assert.is_truthy(dap.adapters.cppdbg or dap.configurations.cpp,
                "C++ DAP adapter should exist")
        end)
    end)

    describe("Breakpoint Functionality", function()
        it("should set breakpoint without error", function()
            local dap = require("dap")
            vim.cmd("new test.lua")
            
            assert.has_no_errors(function()
                dap.set_breakpoint(nil, nil, nil)
            end)
            
            vim.cmd("bdelete!")
        end)

        it("should toggle breakpoint without error", function()
            local dap = require("dap")
            vim.cmd("new test.lua")
            
            assert.has_no_errors(function()
                dap.toggle_breakpoint()
            end)
            
            vim.cmd("bdelete!")
        end)
    end)
end)
