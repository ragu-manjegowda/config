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

    dapui.setup({
      layouts = {
        {
          position = "bottom",
          size = 10,
          elements = {
            { id = "repl", size = 0.50, },
            { id = "console", size = 0.50 },
          },
        },
        {
          position = "right",
          size = 40,
          elements = {
            { id = "scopes", size = 0.46, },
            { id = "stacks", size = 0.36 },
            { id = "breakpoints", size = 0.18 },
            -- { id = "watches", size = 00.25 },
          },
        },
      },
    })

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
end

return M
