local vim = vim

local M = {}

function M.config()
    local map = vim.api.nvim_set_keymap

    map('n', '<leader>dcb',
        '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>',
        { silent = true, desc = 'Set breakpoint with condition' })

    map('n', '<leader>dce', '<cmd>lua require("dap").continue()<CR>',
        { silent = true, desc = 'DAP launch or continue'})

    map('n', '<leader>deb', '<cmd>lua require("dap").set_exception_breakpoints({"all"})<CR>',
        { silent = true, desc = 'Set exception breakpoint' })

    map('n', '<leader>drb', '<cmd>lua require("dap").clear_breakpoints()<CR>',
        { silent = true, desc = 'DAP remove breakpoints' })

    map('n', '<leader>dtb', '<cmd>lua require("dap").toggle_breakpoint()<CR>',
        { silent = true, desc = 'DAP toggle breakpoint' })

    map('n', '<leader>dte', '<cmd>lua require("dap").terminate()<CR>',
        { silent = true, desc = 'DAP terminate'})

    map('n', '<leader>dtr', '<cmd>lua require("dap").repl.toggle()<CR>',
        { silent = true, desc = 'Toggle debugger REPL' })

    map('n', '<leader>dtui', '<cmd>lua require("dapui").toggle()<CR>',
        { silent = true, desc = 'DAP toggle UI' })

    map('n', '<leader>si', '<cmd>lua require("dap").step_into()<CR>',
        { silent = true, desc = 'DAP step into' })

    map('n', '<leader>sn', '<cmd>lua require("dap").step_over()<CR>',
        { silent = true, desc = 'DAP step over' })

    map('n', '<leader>so', '<cmd>lua require("dap").step_out()<CR>',
        { silent = true, desc = 'DAP step out' })

    local res, dap = pcall(require, "dap")
    if not res then
      return
    end

    local dap_virtual_text
    res, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
    if not res then
      return
    end

    dap_virtual_text.setup()

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

    dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = vim.fn.expand('~/.config/nvim/misc/cppdbg/extension/debugAdapters/bin/OpenDebugAD7'),
    }

    dap.configurations.cpp = {
        {
            name = "Launch file",
            type = "cppdbg",
            request = "launch",
            program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            args  = function()
                local argument_string = vim.fn.input('Program arguments: ')
                return vim.fn.split(argument_string, " ", true)
            end,
            cwd = '${workspaceFolder}',
            stopAtEntry = true,
        },
        {
            name = 'Attach to gdbserver :1234',
            type = 'cppdbg',
            request = 'launch',
            MIMode = 'gdb',
            miDebuggerServerAddress = 'localhost:1234',
            miDebuggerPath = '/usr/bin/gdb',
            cwd = '${workspaceFolder}',
            program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            setupCommands = {
                {
                    text = '-enable-pretty-printing',
                    description =  'enable pretty printing',
                    ignoreFailures = false
                },
            },
        },
    }
end

return M