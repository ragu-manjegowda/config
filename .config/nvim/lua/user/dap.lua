local vim = vim

local M = {}

function M.config()
    local map = vim.keymap.set

    map({ 'n', 'v' }, '<F5>', "<cmd>lua require'dap'.continue()<CR>",
      { silent = true, desc = "DAP launch or continue" })
    map({ 'n', 'v' }, '<F8>', "<cmd>lua require'dapui'.toggle()<CR>",
      { silent = true, desc = "DAP toggle UI" })
    map({ 'n', 'v' }, '<F9>', "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
      { silent = true, desc = "DAP toggle breakpoint" })
    map({ 'n', 'v' }, '<F10>', "<cmd>lua require'dap'.step_over()<CR>",
      { silent = true, desc = "DAP step over" })
    map({ 'n', 'v' }, '<F11>', "<cmd>lua require'dap'.step_into()<CR>",
      { silent = true, desc = "DAP step into" })
    map({ 'n', 'v' }, '<F12>', "<cmd>lua require'dap'.step_out()<CR>",
      { silent = true, desc = "DAP step out" })
    map({ 'n', 'v' }, '<leader>dc', "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", { silent = true, desc = "set breakpoint with condition" })
    map({ 'n', 'v' }, '<leader>dp', "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", { silent = true, desc ="set breakpoint with log point message" })
    map({ 'n', 'v' }, '<leader>dr', "<cmd>lua require'dap'.repl.toggle()<CR>",
      { silent = true, desc = "toggle debugger REPL" })

    local res, dap = pcall(require, "dap")
    if not res then
      return
    end

    -- nvim-dap-virtual-text. Show virtual text for current frame
    vim.g.dap_virtual_text = true

    -- configure language adapaters
    dap.adapters.go = function(callback, config)
      local stdout = vim.loop.new_pipe(false)
      local handle
      local pid_or_err
      local host = config.host or "127.0.0.1"
      local port = config.port or "38697"
      local addr = string.format("%s:%s", host, port)
      local opts = {
        stdio = {nil, stdout},
        args = {"dap", "-l", addr},
        detached = true
      }
      handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
        stdout:close()
        handle:close()
        if code ~= 0 then
          print('dlv exited with code', code)
        end
      end)
      assert(handle, 'Error running dlv: ' .. tostring(pid_or_err))
      stdout:read_start(function(err, chunk)
        assert(not err, err)
        if chunk then
          vim.schedule(function()
            require('dap.repl').append(chunk)
          end)
        end
      end)
      -- Wait for delve to start
      vim.defer_fn(
      function()
        callback({type = "server", host = "127.0.0.1", port = port})
      end,
      100)
    end

    dap.configurations.go = {
      {
        type = "go",
        name = "Debug",
        request = "launch",
        program = "${file}",
      },
      {
        type = "go",
        name = "Debug Package",
        request = "launch",
        program = "${fileDirname}",
      },
      {
        type = "go",
        name = "Attach",
        mode = "local",
        request = "attach",
        processId = require('dap.utils').pick_process,
      },
      {
        type = "go",
        name = "Debug test",
        request = "launch",
        mode = "test",
        program = "${file}",
      },
      {
        type = "go",
        name = "Debug test (go.mod)",
        request = "launch",
        mode = "test",
        program = "./${relativeFileDirname}",
      }
    }
end

return M
