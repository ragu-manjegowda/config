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

    -- Shift the focus to terminal, avoid focusing buffer in insert mode
    -- because of TermOpen autocmd
    ---@diagnostic disable-next-line: undefined-field
    dap.defaults.fallback.focus_terminal = true

    -- Configure language adapaters

    -- C++ adapters
    local path
    res, path = pcall(require, "mason-core.path")
    if not res then
        vim.notify("mason-core.path not found", vim.log.levels.ERROR)
        return
    end


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
        },
    }

    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.cpp = {
        {
            name          = "Launch file",
            type          = "cppdbg",
            request       = "launch",
            program       = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            args          = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end,
            cwd           = function()
                return vim.fn.input("Program working directory: ", vim.fn.getcwd() .. "/", "file")
            end,
            setupCommands = {
                {
                    text = "-enable-pretty-printing",
                    description = "enable pretty printing",
                    ignoreFailures = false
                },
            },

            stopAtEntry   = true,
        },
        {
            name = "Attach to gdbserver :1234",
            type = "cppdbg",
            request = "launch",
            MIMode = "gdb",
            miDebuggerServerAddress = "localhost:1234",
            miDebuggerPath = "/usr/bin/gdb",
            cwd = function()
                return vim.fn.input("Program working directory: ", vim.fn.getcwd() .. "/", "file")
            end,
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            setupCommands = {
                {
                    text = "-enable-pretty-printing",
                    description = "enable pretty printing",
                    ignoreFailures = false
                },
            },
        },
    }

    -- Re-use this for C and Rust
    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.c = dap.configurations.cpp
    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.rust = dap.configurations.cpp


    -- Go adapters
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
            -- dlv exec --headless -l=:38697 ./goimapnotify -- -conf /home/ragu/.config/imapnotify/imapnotify.conf
            type           = "go",
            name           = "Attach",
            mode           = "remote",
            request        = "attach",
            port           = "38697",
            processId      = require("dap.utils").pick_process,
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

    -- Python adapters
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
            host = "localhost",
            port = 3000,
        })
    end

    ---@diagnostic disable-next-line: undefined-field
    dap.configurations.python = {
        {
            type        = "python",
            request     = "launch",
            name        = "Launch file",

            program     = function()
                return vim.fn.input("Path to file: ",
                    vim.fn.expand("%"), "file")
            end,
            args        = function()
                local argument_string = vim.fn.input("Program arguments: ")
                return vim.fn.split(argument_string, " ", true)
            end,

            cwd         = function()
                return vim.fn.input("Program working directory: ",
                    vim.fn.getcwd() .. "/", "file")
            end,

            stopAtEntry = true
        },
        {
            type = "remote_python",
            request = "attach",
            name = "Remote attach",
            port = 3000,
            host = "localhost",

            stopAtEntry = true
        },
    }
end

return M
