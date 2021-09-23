
lua << EOF

local HOME = os.getenv('HOME')

local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = HOME .. '/Documents/homebrew/opt/llvm/bin/lldb-vscode',
  name = "lldb"
}

local dap = require('dap')
dap.configurations.cpp = {
  {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},

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
    runInTerminal = false,
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
}


-- If you want to use this for rust and c, add something like this:

dap.configurations.c = dap.configurations.cpp
dap.configurations.cpp = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

EOF
