-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

local res, utils = pcall(require, "user.utils")
if not res then
    vim.notify("Error loading user.utils", vim.log.levels.ERROR)
    return
end

local dap
res, dap = pcall(require, "dap")
if not res then
    vim.notify("dap not found", vim.log.levels.ERROR)
    return
end

local keymap_opts = function(desc)
    return {
        desc = "DAP: " .. desc
    }
end

-- DAP keymaps
---@return nil
function M.define_mappings()
    utils.keymap("n", "<leader>dcb",
        '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>',
        keymap_opts("set breakpoint with condition"))

    utils.keymap("n", "<leader>dce", '<cmd>lua require("dap").continue()<CR>',
        keymap_opts("launch or continue"))

    utils.keymap("n", "<leader>deb", '<cmd>lua require("dap").set_exception_breakpoints({"all"})<CR>',
        keymap_opts("set exception breakpoint"))

    utils.keymap("n", "<leader>drb", '<cmd>lua require("dap").clear_breakpoints()<CR>',
        keymap_opts("remove breakpoints"))

    utils.keymap("n", "<leader>drc", '<cmd>lua require("dap").run_to_cursor()<CR>',
        keymap_opts("run to cursor"))

    utils.keymap("n", "<leader>drl", '<cmd>lua require("dap").run_last()<CR>',
        keymap_opts("re-run last adapter configuration"))

    utils.keymap("n", "<leader>drr", '<cmd>lua require("dap").restart()<CR>',
        keymap_opts("restart"))

    utils.keymap("n", "<leader>dtb", '<cmd>lua require("dap").toggle_breakpoint()<CR>',
        keymap_opts("toggle breakpoint"))

    utils.keymap("n", "<leader>dte", '<cmd>lua require("dap").terminate()<CR>',
        keymap_opts("terminate"))

    utils.keymap("n", "<leader>dtui", '<cmd>lua require("dapui").toggle()<CR>',
        keymap_opts("toggle UI"))

    utils.keymap("n", "<leader>si", '<cmd>lua require("dap").step_into()<CR>',
        keymap_opts("step into"))

    utils.keymap("n", "<leader>sn", '<cmd>lua require("dap").step_over()<CR>',
        keymap_opts("step over"))

    utils.keymap("n", "<leader>so", '<cmd>lua require("dap").step_out()<CR>',
        keymap_opts("step out"))
end

-- DAP Pick file filter for bazel projects
-- Choose only from runfiles sandbox under bazel-bin
---@param opts? { dir: boolean, executables?: boolean }
---@return {
---path?: string, filter?: string|(fun(name: string): boolean),
---executables?: boolean, directories?: boolean, prompt?: string }
local bazel_filter           = function(opts)
    local filter = nil
    local file_path = nil
    local prompt = nil

    opts = opts or {}
    local executables = opts.executables == nil and true or opts.executables
    local directories = opts.dir == nil and true or opts.dir

    if utils.is_bazel_project() then
        -- Bazel puts sandbox under folder named `*.runfiles`
        filter = function(filepath)
            return string.find(filepath, "runfiles") ~= nil
        end

        file_path = vim.fn.getcwd() .. "/bazel-bin"
        executables = false
    else
        -- For non interpreted projects (python) do not look for executables
        -- opts.executables is set to false explicitly
        if opts.executables == nil then
            executables = true
        end
    end

    if directories == true then
        prompt = "Pick a directory:"
    else
        if executables == true then
            prompt = "Pick an executable:"
        else
            prompt = "Pick a file:"
        end
    end

    return {
        path = file_path,
        filter = filter,
        executables = executables,
        directories = directories,
        prompt = prompt
    }
end

---@param opts { dir: boolean, executables?: boolean }
---@return string|thread
local pick_file_or_directory = function(opts)
    local options = bazel_filter(opts)
    local filepath = utils.pick_file(options)
    ---@diagnostic disable-next-line: undefined-field
    return filepath or dap.ABORT
end

---@param executables? boolean
---@return string|thread
local pick_program           = function(executables)
    return pick_file_or_directory({ dir = false, executables = executables })
end

---@return string|thread
local pick_cwd               = function()
    return pick_file_or_directory({ dir = true })
end

-- DAP setup for C++
---@return nil
function M.setup_cpp_adapters()
    --- GDB adapter
    local gdb_debugger_path = "gdb"

    local path_components = {
        vim.fn.stdpath "data",
        "mason",
        "bin",
        "OpenDebugAD7"
    }

    local dbg_command = table.concat(path_components, "/")

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = dbg_command
    }

    --- LLDB adapter
    local lldb_debugger_path
    local lldb_dap_debugger_path = "lldb-dap"

    ---@diagnostic disable-next-line: undefined-field
    if vim.loop.os_uname().sysname == "Darwin" then
        -- On Mac lldb is at `/usr/local/opt/llvm/bin`
        lldb_debugger_path = "/usr/local/opt/llvm/bin/lldb"
        lldb_dap_debugger_path = "/usr/local/opt/llvm/bin/lldb-dap"
    end

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.cppdbglldb             = {
        id = "cppdbglldb",
        type = "executable",
        command = lldb_dap_debugger_path,
    }

    local display_env                   = {
        -- export DISPLAY=:0.0
        DISPLAY = os.getenv "DISPLAY",
    }
    -- Pretty printing setup
    -- Ref: https://github.com/microsoft/vscode-cpptools/issues/8485#issuecomment-1912764586
    local setup_commands                = {
        {
            text = "-enable-pretty-printing",
            description = "enable pretty printing",
            ignoreFailures = true
        },
        {
            description = "Without this, gdb won't load the scripts from this dir",
            text = "add-auto-load-safe-path /usr/share/gdb/auto-load"
        },
        {
            description = "Without this, things like pretty-printing will not work",
            text = "add-auto-load-scripts-directory /usr/share/gdb/auto-load"
        }
    }

    -- Create a config for cppdbg
    local cppdbg_config                 = {
        name          = "Launch file (gdb)",
        type          = "cppdbg",
        request       = "launch",
        program       = pick_program,
        args          = function()
            local argument_string = vim.fn.input("Program arguments: ")
            return vim.fn.split(argument_string, " ", true)
        end,
        cwd           = pick_cwd,
        setupCommands = setup_commands,
        env           = display_env,
        stopAtEntry   = true
    }

    -- Create a shallow copy of cppdbg_config modified for lldb
    local cppdbg_lldb_config            = vim.tbl_extend(
        "force",
        cppdbg_config,
        {
            name         = "Launch file (lldb)",
            type         = "cppdbglldb",
            -- https://github.com/vadimcn/codelldb/issues/258#issuecomment-1296347970
            initCommands = { "breakpoint set -n main -N entry" },
            exitCommands = { "breakpoint delete entry" },
            stopOnEntry  = false
        }
    )

    -- Create a config for cppdbg remote
    -- Use this to start server `gdbserver localhost:1234 test`
    local cppdbg_remote_config          = {
        name = "Attach to gdbserver :1234",
        type = "cppdbg",
        request = "launch",
        MIMode = "gdb",
        miDebuggerServerAddress = "localhost:1234",
        miDebuggerPath = gdb_debugger_path,
        cwd = cppdbg_config.cwd,
        program = cppdbg_config.program,
        setupCommands = setup_commands,
        stopAtEntry = true
    }

    -- Create a shallow copy of cppdbg_remote_config modified for lldb (MacOS)
    -- Use this to start server `/usr/local/opt/llvm/bin/lldb-server platform --listen localhost:1234`
    local cppdbg_lldb_remote_config_mac = vim.tbl_extend(
        "force",
        cppdbg_remote_config,
        {
            name           = "Attach to lldbserver :1234",
            type           = "cppdbglldb",
            MIMode         = "lldb",
            miDebuggerPath = lldb_debugger_path,
            args           = cppdbg_config.args,
            -- https://github.com/vadimcn/codelldb/issues/258#issuecomment-1296347970
            initCommands   = { "breakpoint set -n main -N entry" },
            exitCommands   = { "breakpoint delete entry" },
            stopOnEntry    = false
        }
    )

    -- Create a shallow copy of cppdbg_remote_config modified for lldb
    -- Use this to start server `lldb-server gdbserver localhost:1234 test`
    local cppdbg_lldb_remote_config     = vim.tbl_extend(
        "force",
        cppdbg_remote_config,
        {
            name           = "Attach to lldbserver :1234",
            type           = "cppdbglldb",
            request        = "attach",
            cwd            = "",
            args           = "",
            attachCommands = { "gdb-remote 1234" },
            -- https://github.com/vadimcn/codelldb/issues/258#issuecomment-1296347970
            initCommands   = { "breakpoint set -n main -N entry" },
            exitCommands   = { "breakpoint delete entry" },
            stopOnEntry    = false
        }
    )

    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.cpp              = {
        cppdbg_lldb_config,
    }

    -- GDB needs code signing on mac, stick to lldb
    ---@diagnostic disable-next-line: undefined-field
    if vim.loop.os_uname().sysname ~= "Darwin" then
        ---@diagnostic disable-next-line: undefined-field
        table.insert(dap.configurations.cpp, cppdbg_config)
        ---@diagnostic disable-next-line: undefined-field
        table.insert(dap.configurations.cpp, cppdbg_remote_config)
        ---@diagnostic disable-next-line: undefined-field
        table.insert(dap.configurations.cpp, cppdbg_lldb_remote_config)
    else
        ---@diagnostic disable-next-line: undefined-field
        table.insert(dap.configurations.cpp, cppdbg_lldb_remote_config_mac)
    end

    -- Re-use this for C and Rust
    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.c = dap.configurations.cpp
    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.rust = dap.configurations.cpp
end

--- DAP setup for Go
---@return nil
function M.setup_go_adapters()
    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.go = function(callback, config)
        -- https://neovim.io/doc/user/luvref.html#uv.new_pipe()
        ---@diagnostic disable-next-line: undefined-field
        local stdout = vim.uv.new_pipe(false)
        local handle
        local pid_or_err
        local host = config.host or "127.0.0.1"
        local port = config.port or "38697"
        local addr = string.format("%s:%s", host, port)
        local opts = {
            stdio = { nil, stdout },
            args = { "dap", "-l", addr },
            detached = true
        }
        -- https://neovim.io/doc/user/luvref.html#uv.spawn()
        ---@diagnostic disable-next-line: undefined-field
        handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
            stdout:close()
            handle:close()
            if code ~= 0 then
                print("dlv exited with code " .. code)
            end
        end)
        assert(handle, "Error running dlv: " .. tostring(pid_or_err))
        ---@diagnostic disable-next-line: undefined-field
        stdout:read_start(function(err, chunk)
            assert(not err, err)
            if chunk then
                vim.schedule(function()
                    require("dap.repl").append(chunk)
                end)
            end
        end)
        -- Wait for delve to start
        vim.defer_fn(
            function()
                callback({ type = "server", host = "127.0.0.1", port = port })
            end,
            100)
    end

    local dap_utils
    res, dap_utils = pcall(require, "dap.utils")
    if not res then
        vim.notify("dap.utils not found", vim.log.levels.ERROR)
        return
    end

    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.go = {
        {
            type    = "go",
            name    = "Debug",
            request = "launch",
            program = "${file}",

            args    = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end
        },
        {
            type    = "go",
            name    = "Debug Package",
            request = "launch",
            program = "${fileDirname}",

            args    = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end
        },
        {
            -- Run dlv server then pick the process
            -- Compile with
            --      * `go build -gcflags="all=-N -l" -o target_name`
            --      * `bazel build -c dbg //path_to_target`
            -- dlv exec --headless -l=:1234 ./goimapnotify -- -conf /home/ragu/.config/imapnotify/imapnotify.conf
            type           = "go",
            name           = "Attach",
            mode           = "remote",
            request        = "attach",
            port           = "1234",
            processId      = dap_utils.pick_process,
            trace          = "log",
            logOutput      = "rpc",
            substitutePath = {
                {
                    from = "${workspaceFolder}/bazel-${workspaceFolderBasename}/external/",
                    to = "external/",
                },
                {
                    from = "external/",
                    to = "${workspaceFolder}/bazel-${workspaceFolderBasename}/external/",
                },
                {
                    from = "GOROOT/",
                    to = "${workspaceFolder}/bazel-${workspaceFolderBasename}/external/go_sdk/",
                },
                {
                    from = "${workspaceFolder}/bazel-${workspaceFolderBasename}/external/go_sdk/",
                    to = "GOROOT/",
                },
                {
                    from = "",
                    to =
                    "${workspaceFolder}"
                },
                {
                    from = "${workspaceFolder}",
                    to = ""
                }
            }
        },
        {
            type    = "go",
            name    = "Debug test",
            request = "launch",
            mode    = "test",
            program = "${file}",

            args    = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end
        },
        {
            type    = "go",
            name    = "Debug test (go.mod)",
            request = "launch",
            mode    = "test",
            program = "./${relativeFileDirname}",

            args    = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end
        }
    }
end

-- DAP setup for Python
---@return nil
function M.setup_python_adapters()
    local path_components = {
        vim.fn.stdpath "data",
        "mason",
        "packages",
        "debugpy",
        "venv",
        "bin",
        "python"
    }

    local dbg_command = table.concat(path_components, "/")

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.python = {
        type = "executable",
        command = dbg_command,
        args = { "-m", "debugpy.adapter" }
    }

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.remote_python = function(callback)
        callback({
            type = "server",
            host = "127.0.0.1",
            port = 1234,
        })
    end

    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.python = {
        {
            type        = "python",
            request     = "launch",
            name        = "Launch file",
            program     = function()
                return pick_program(false)
            end,
            args        = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end,
            cwd         = pick_cwd,
            console     = "integratedTerminal",
            stopOnEntry = true
        },
        -- Use the following to start a server
        -- `python -m debugpy --listen 1234 --wait-for-client target.py`
        -- Within Neovim, set breakpoint and run `lua require('dap').continue()`
        --
        -- For Address already in use error, use the following
        -- `fuser -k 1234/tcp`
        {
            type           = "remote_python",
            request        = "attach",
            name           = "Remote attach",
            port           = 1234,
            host           = "127.0.0.1",
            redirectOutput = true,
            console        = "integratedTerminal",
            stopOnEntry    = true
        }
    }
end

function M.config()
    -- Define keymaps
    M.define_mappings()

    local dap_virtual_text
    res, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
    if not res then
        vim.notify("nvim-dap-virtual-text not found", vim.log.levels.WARN)
    else
        ---@diagnostic disable-next-line: missing-fields
        dap_virtual_text.setup({
            virt_text_pos = "eol"
        })
    end

    -- Shift the focus to terminal, avoid focusing buffer in insert mode
    -- because of TermOpen autocmd
    ---@diagnostic disable-next-line: undefined-field
    dap.defaults.fallback.focus_terminal = true

    ---------------------------------------------------------------------------
    -- Configure language adapaters
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- C++ adapters
    ---------------------------------------------------------------------------
    M.setup_cpp_adapters()

    ---------------------------------------------------------------------------
    -- Go adapters
    ---------------------------------------------------------------------------
    M.setup_go_adapters()

    ---------------------------------------------------------------------------
    -- Python adapters
    ---------------------------------------------------------------------------
    M.setup_python_adapters()
end

return M
