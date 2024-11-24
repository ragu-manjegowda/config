-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

local res, protocol = pcall(require, "vim.lsp.protocol")
if not res then
    vim.notify("lsp.protocol not found", vim.log.levels.ERROR)
    return
end

local signs = { Error = "", Hint = "", Info = "", Information = "", Warn = "" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = "", numhl = "" })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local function on_attach(client, bufnr)
    local map = vim.keymap.set

    -- Enable completion triggered by <c-x><c-o>
    -- <c-x><c-o> is also mapped to <c-d> in options.lua via wildchar
    -- buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
    vim.opt.omnifunc = "v:lua.vim.lsp.omnifunc"

    map({ 'n', 'v' }, '<leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>',
        { silent = true, desc = 'LSP formatting' })

    local rc = client.server_capabilities

    -- Pyright is pretty much useless, disabling most of the stuff and keeping
    -- around for now.
    if client.name == 'pyright' then
        rc.callHierarchyProvider = false
        rc.completion = false
        rc.completionProvider = false
        rc.declarationProvider = false
        rc.definitionProvider = false
        rc.definitions = false
        rc.hover = false
        rc.hoverProvider = false
        rc.rename = false
        rc.renameProvider = false
        rc.signatureHelpProvider = false
        rc.signature_help = false
    end

    local lsp_signature
    res, lsp_signature = pcall(require, "lsp_signature")
    if not res then
        vim.notify("lsp_signature not found", vim.log.levels.WARN)
    else
        lsp_signature.setup({
            doc_lines = 0,
            hint_enable = false,
            select_signature_key = "<M-n>"
        }, bufnr)

        map({ 'n', 'i' }, '<C-k>',
            '<cmd>lua require("lsp_signature").toggle_float_win()<CR>',
            { silent = true, desc = 'Toggle LSP signature' })
    end

    local lsp_inlayhints
    res, lsp_inlayhints = pcall(require, "lsp-inlayhints")
    if not res then
        vim.notify("lsp-inlayhints not found", vim.log.levels.WARN)
    else
        lsp_inlayhints.on_attach(client, bufnr)
    end

    --protocol.SymbolKind = { }
    protocol.CompletionItemKind = {
        '', -- Text
        '', -- Method
        '', -- Function
        '', -- Constructor
        '', -- Field
        '', -- Variable
        '', -- Class
        'ﰮ', -- Interface
        '', -- Module
        '', -- Property
        '', -- Unit
        '', -- Value
        '', -- Enum
        '', -- Keyword
        '﬌', -- Snippet
        '', -- Color
        '', -- File
        '', -- Reference
        '', -- Folder
        '', -- EnumMember
        '', -- Constant
        '', -- Struct
        '', -- Event
        'ﬦ', -- Operator
        '', -- TypeParameter
    }
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
        underline = false,
        virtual_text = false,
        signs = {
            active = signs,
        },
    }
)

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'rounded' }
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    { border = 'rounded' }
)

function M.config()
    local nvim_lsp, cmp_nvim_lsp, lsp_windows
    res, nvim_lsp = pcall(require, "lspconfig")
    if not res then
        vim.notify("lspconfig not found", vim.log.levels.ERROR)
        return
    end

    res, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if not res then
        vim.notify("cmp_nvim_lsp not found", vim.log.levels.ERROR)
        return
    end

    local lsp_inlayhints
    res, lsp_inlayhints = pcall(require, "lsp-inlayhints")
    if not res then
        vim.notify("lsp-inlayhints not found", vim.log.levels.WARN)
    else
        vim.api.nvim_create_user_command(
            'ToggleInlayHints',
            function()
                lsp_inlayhints.toggle()
            end, {}
        )
    end

    res, lsp_windows = pcall(require, "lspconfig.ui.windows")
    if not res then
        vim.notify("lspconfig.ui.windows not found", vim.log.levels.ERROR)
        return
    end

    lsp_windows.default_options.border = "rounded"

    -- Add cmp_nvim_lsp capabilities to default capabilities
    local lsp_defaults = nvim_lsp.util.default_config

    lsp_defaults.capabilities =
        vim.tbl_deep_extend(
            'force',
            lsp_defaults.capabilities,
            cmp_nvim_lsp.default_capabilities())

    nvim_lsp.util.default_config = lsp_defaults

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Bash
    nvim_lsp.bashls.setup {
        on_attach = on_attach
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- C, C++
    local clangd_cmd = {
        "clangd",
        "--all-scopes-completion=true",
        "--background-index",
        "--background-index-priority=low",
        "--clang-tidy",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--header-insertion=never",
        -- "--include-directory=include/**",
        "-j=4",
        "--pch-storage=memory",
        "--use-dirty-headers",
        -- You MUST set this arg ↓ to your clangd executable location (if not included)!
        -- "--query-driver=/usr/bin/clang++,/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
        -- "--std=c++17",
        -- "--std=c11",
    }

    ---@diagnostic disable-next-line: undefined-field
    if not vim.loop.os_uname().sysname == "Darwin" then
        -- Linux specific exclude this on Mac
        table.insert(clangd_cmd, "--enable-config")
        table.insert(clangd_cmd, "--malloc-trim")
    end

    nvim_lsp.clangd.setup {
        on_attach = on_attach,
        root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
        cmd = clangd_cmd
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Cmake
    nvim_lsp.cmake.setup {
        on_attach = on_attach
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Golang
    -- https://github.com/bazelbuild/rules_go/wiki/Editor-setup
    -- https://github.com/AnatoleLucet/dotfiles/blob/9f329f8d624655ab262329e12531eb1dfb54df15/nvim.save/.config/nvim/lua/lsp/init.lua#L153

    local cwd = vim.fn.getcwd()

    local gopackagesdriver = ""
    local bazel_workspace_dir = ""
    local goroot = ""

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("user.utils not found", vim.log.levels.ERROR)
        return
    end

    if utils.isBazelProject() then
        gopackagesdriver = cwd .. "/scripts/gopackagesdriver.sh"
        if vim.fn.filereadable(gopackagesdriver) ~= 1 then
            gopackagesdriver = ""
        end

        goroot = cwd .. "/bazel-" .. cwd:match("/([^/]*)$") .. "/external/go_sdk"
        if vim.fn.isdirectory(goroot) ~= 1 then
            goroot = ""
        end

        bazel_workspace_dir = vim.fn.fnamemodify(cwd, ':t')
    end

    nvim_lsp.gopls.setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        cmd = { "gopls", "serve" },
        filetypes = { "go", "gomod" },
        root_dir = nvim_lsp.util.root_pattern("go.mod", ".gitignore"),
        settings = {
            gopls = {
                analyses = {
                    unusedparams = true,
                },
                directoryFilters = {
                    "-bazel-bin",
                    "-bazel-out",
                    "-bazel-testlogs",
                    "-bazel-" .. bazel_workspace_dir,
                },
                env = {
                    GOROOT = goroot,
                    GOPACKAGESDRIVER_BAZEL_BUILD_FLAGS = "--strategy=GoStdlibList=local",
                    GOPACKAGESDRIVER_BAZEL_QUERY = "kind(go_binary, //...)",
                    GOPACKAGESDRIVER = gopackagesdriver
                },
                staticcheck = true
            }
        }
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Json
    nvim_lsp.jsonls.setup {
        on_attach = on_attach
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Lua
    nvim_lsp.lua_ls.setup {
        on_attach = on_attach,
        -- root_dir is .luacheckrc which is added for both awesome and nvim
        settings = {
            Lua = {
                completion = {
                    keywordSnippet = "Both",
                    callSnippet = "Both"
                },
                hint = { enable = true },
                telemetry = { enable = false }
            }
        }
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Markdown

    -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
    -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
    local watch_capabilities = vim.tbl_deep_extend(
        'force',
        lsp_defaults.capabilities,
        {
            workspace = {
                didChangeWatchedFiles = {
                    dynamicRegistration = true,
                },
            },
        }
    )

    nvim_lsp.marksman.setup {
        capabilities = watch_capabilities,
        on_attach = on_attach
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Python
    -- https://www.reddit.com/r/neovim/comments/sazbw6/comment/hw1s6qg/?utm_source=share&utm_medium=web2x&context=3

    -- Set heap size to 4GB - https://github.com/microsoft/pyright/issues/3239
    -- exclude this on Mac, we know it's 4GB, issue is mostly on Ubuntu
    ---@diagnostic disable-next-line: undefined-field
    if not vim.loop.os_uname().sysname == "Darwin" then
        local cmd = "node -e 'console.log(v8.getHeapStatistics().total_available_size / 1024 / 1024)'"
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        if tonumber(s) < 4096 then
            vim.env.NODE_OPTIONS = "--max-old-space-size=4096"
        end
    end

    nvim_lsp.pyright.setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        settings = {
            python = {
                analysis = {
                    autoImportCompletions = false,
                    diagnosticMode = "openFilesOnly",
                    -- diagnosticSeverityOverrides = {
                    --     reportGeneralTypeIssues = "none",
                    --     reportOptionalMemberAccess = "none",
                    --     reportOptionalSubscript = "none",
                    --     reportPrivateImportUsage = "none",
                    -- },
                    useLibraryCodeForTypes = true
                },
                linting = { pylintEnabled = false }
            },
        },
    }

    -- Pylsp for hover, documentation, go to definition, syntax checking
    -- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
    nvim_lsp.pylsp.setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        settings = {
            pylsp = {
                plugins = {
                    jedi_completion = {
                        fuzzy = true
                    },
                    flake8 = { enabled = true },
                    pycodestyle = {
                        ignore = {
                            'C0103', 'E266',
                            'W0104', 'W391', 'W503', 'W504'
                        },
                        maxLineLength = 80
                    },
                    pydocstyle = { enabled = true },
                    pyflakes = { enabled = false },
                },
            },
        },
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Rust
    nvim_lsp.rust_analyzer.setup {
        on_attach = on_attach,
        settings = {
            ["rust-analyzer"] = {
                imports = {
                    granularity = {
                        group = "module",
                    },
                    prefix = "self",
                },
                cargo = {
                    buildScripts = {
                        enable = true,
                    },
                },
                procMacro = {
                    enable = true
                },
                inlayHints = {
                    enabled = true,
                    typeHints = {
                        enable = true,
                    },
                },
            }
        }
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Toml
    nvim_lsp.harper_ls.setup {
        on_attach = on_attach,
        filetypes = { "html", "ruby", "toml" },
        settings = {
            ["harper-ls"] = {
                linters = {
                    spell_check = false,
                    sentence_capitalization = false,
                },
            }
        }
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Vim
    nvim_lsp.vimls.setup {
        on_attach = on_attach
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Yaml
    nvim_lsp.yamlls.setup {
        on_attach = on_attach
    }
end

return M
