
lua << EOF

local HOME = os.getenv('HOME')

local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = HOME .. '/Documents/homebrew/opt/llvm/bin/lldb-vscode',
  name = "lldb"
}

dap.adapters.cppdbg = {
  type = 'executable',
  command = HOME .. '/.config/nvim/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '/media/ragu/drive/sdk/bazel-bin',
    stopOnEntry = true,
    args = function()
      local argument_string = vim.fn.input('Program arguments: ')
      return vim.fn.split(argument_string, " ", true)
    end,

    -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
    --
    --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    --
    -- Otherwise you might get the following error:
    --
    --    Error on launch: Failed to attach to the target process
    --
    -- But you should be aware of the implications:
    -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
    runInTerminal = true,
  },
  {
    -- If you get an "Operation not permitted" error using this, try disabling YAMA:
    --  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    name = "Attach to process",
    type = 'lldb',
    request = 'attach',
    pid = require('dap.utils').pick_process,
    args = {},
  },
  {
    name = 'Attach to gdbserver',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:2159',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '/media/ragu/drive/sdk/bazel-bin',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
  },
}


-- If you want to use this for rust and c, add something like this:

dap.configurations.c = dap.configurations.cpp
dap.configurations.cpp = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

EOF
