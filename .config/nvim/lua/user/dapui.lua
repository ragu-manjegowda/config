local vim = vim

local M = {}

function M.config()
    local res, dapui = pcall(require, "dapui")
    if not res then
      return
    end

    local dap
    res, dap = pcall(require, "dap")
    if not res then
      return
    end

    -- Change debugging icons
    vim.fn.sign_define('DapBreakpointCondition', { text = 'Ω', texthl = 'Red', linehl = '', numhl = 'Red' })
    vim.fn.sign_define('DapBreakpoint', { text = '⬢', texthl = 'Red', linehl = '', numhl = 'Red' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'Green', linehl = 'ColorColumn', numhl = 'Green' })

    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
        dap.repl.close()
        dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"]     = function()
        dap.repl.close()
        dapui.close()
    end
    dap.listeners.before.disconnect["dapui_config"]       = function()
        dap.repl.close()
        dapui.close()
    end
end

return M
