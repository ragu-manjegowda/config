-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local map = vim.api.nvim_set_keymap

    map('n', '<leader>dcb',
        '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>',
        { silent = true, desc = 'DAP set breakpoint with condition' })

    map('n', '<leader>dce', '<cmd>lua require("dap").continue()<CR>',
        { silent = true, desc = 'DAP launch or continue' })

    map('n', '<leader>deb', '<cmd>lua require("dap").set_exception_breakpoints({"all"})<CR>',
        { silent = true, desc = 'DAP set exception breakpoint' })

    map('n', '<leader>drb', '<cmd>lua require("dap").clear_breakpoints()<CR>',
        { silent = true, desc = 'DAP remove breakpoints' })

    map('n', '<leader>drc', '<cmd>lua require("dap").run_to_cursor()<CR>',
        { silent = true, desc = 'DAP run to cursor' })

    map('n', '<leader>drl', '<cmd>lua require("dap").run_last()<CR>',
        { silent = true, desc = 'DAP re-run last adapter configuration' })

    map('n', '<leader>drr', '<cmd>lua require("dap").restart()<CR>',
        { silent = true, desc = 'DAP restart' })

    map('n', '<leader>dtb', '<cmd>lua require("dap").toggle_breakpoint()<CR>',
        { silent = true, desc = 'DAP toggle breakpoint' })

    map('n', '<leader>dte', '<cmd>lua require("dap").terminate()<CR>',
        { silent = true, desc = 'DAP terminate' })

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
        vim.notify("dap not found", vim.log.levels.ERROR)
        return
    end

    local dap_virtual_text
    res, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
    if not res then
        vim.notify("nvim-dap-virtual-text not found", vim.log.levels.ERROR)
    else
        dap_virtual_text.setup({
            virt_text_pos = "eol"
        })
    end

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("user.utils not found", vim.log.levels.ERROR)
        return
    end

    local dap_utils
    res, dap_utils = pcall(require, "dap.utils")
    if not res then
        vim.notify("dap.utils not found", vim.log.levels.ERROR)
        return
    end

    -- Shift the focus to terminal, avoid focusing buffer in insert mode
    -- because of TermOpen autocmd
    ---@diagnostic disable-next-line: undefined-field
    dap.defaults.fallback.focus_terminal = true

    local path
    res, path = pcall(require, "mason-core.path")
    if not res then
        vim.notify("mason-core.path not found", vim.log.levels.ERROR)
        return
    end

    ---------------------------------------------------------------------------
    -- Configure language adapaters
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- C++ adapters
    ---------------------------------------------------------------------------

    --- GDB adapter

    local gdb_debugger_path = "gdb"

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = path.concat {
            ---@diagnostic disable-next-line: assign-type-mismatch
            vim.fn.stdpath "data",
            "mason",
            "bin",
            "OpenDebugAD7"
        }
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

    -- DAP Pick file filter for bazel projects
    -- Choose only from runfiles sandbox under bazel-bin
    ---@param opts? { dir: boolean, executables?: boolean }
    ---@return {
    ---path?: string, filter?: string|(fun(name: string): boolean),
    ---executables?: boolean, directories?: boolean, prompt?: string }
    local bazel_filter                  = function(opts)
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

    ---@param directory boolean
    ---@return string|thread
    local pick_file_or_directory        = function(directory)
        local opts = bazel_filter({ dir = directory })
        local filepath = utils.pick_file(opts)
        ---@diagnostic disable-next-line: undefined-field
        return filepath or dap.ABORT
    end

    ---@return string|thread
    local pick_program                  = function()
        return pick_file_or_directory(false)
    end

    ---@return string|thread
    local pick_cwd                      = function()
        return pick_file_or_directory(true)
    end

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


    ---------------------------------------------------------------------------
    -- Go adapters
    ---------------------------------------------------------------------------

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

    ---------------------------------------------------------------------------
    -- Python adapters
    ---------------------------------------------------------------------------

    ---@diagnostic disable-next-line: undefined-field
    dap.adapters.python = {
        type = "executable",
        command = path.concat
            {
                ---@diagnostic disable-next-line: assign-type-mismatch
                vim.fn.stdpath "data",
                "mason",
                "packages",
                "debugpy",
                "venv",
                "bin",
                "python"
            },
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
            program     = pick_program,
            args        = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end,
            cwd         = pick_cwd,
            stopOnEntry = true
        },
        -- Use the following to start a server
        -- `python -m debugpy --listen 1234 --wait-for-client target.py`
        -- Within Neovim, set breakpoint and run `lua require('dap').continue()`
        --
        -- For Address already in use error, use the following
        -- `fuser -k 1234/tcp`
        {
            type = "remote_python",
            request = "attach",
            name = "Remote attach",
            port = 1234,
            host = "127.0.0.1",
            redirectOutput = true,
            stopOnEntry = true
        }
    }
end

return M
