local vim = vim

local M = {}

function M.config()
    -- Setup DAPUI
    local res, dapui = pcall(require, "dapui")
    if not res then
        vim.notify("dapui not found", vim.log.levels.ERROR)
        return
    end

    dapui.setup()

    -- Change debugging icons
    vim.fn.sign_define("DapBreakpoint",
        { text = "", texthl = "DapBreakpoint" })

    vim.fn.sign_define("DapBreakpointCondition",
        { text = "", texthl = "DapBreakpointCondition" })

    vim.fn.sign_define("DapBreakpointRejected",
        { text = "", texthl = "DapBreakpointCondition" })

    vim.fn.sign_define("DapLogPoint",
        { text = "", texthl = "DapLogPoint" })

    vim.fn.sign_define("DapStopped",
        { text = "→", texthl = "DapStopped" })

    -- Add DAPUI hooks for DAP
    local dap
    res, dap = pcall(require, "dap")
    if not res then
        vim.notify("dap not found", vim.log.levels.ERROR)
        return
    end

    dap.listeners.after.event_initialized["dapui_config"] = function()
        ---@diagnostic disable-next-line: missing-parameter
        dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
        ---@diagnostic disable-next-line: missing-parameter
        dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"]     = function()
        ---@diagnostic disable-next-line: missing-parameter
        dapui.close()
    end
    dap.listeners.before.disconnect["dapui_config"]       = function()
        ---@diagnostic disable-next-line: missing-parameter
        dapui.close()
    end

    -- Set DAPUI keymaps
    local map = vim.api.nvim_set_keymap

    map("n", "<leader>dex",
        '<cmd>lua require("dapui").eval()<CR>',
        { silent = true, desc = "DAP eval expression" })

    map("v", "<leader>dex",
        '<cmd>lua require("dapui").eval()<CR>',
        { silent = true, desc = "DAP eval expression" })
end

return M
