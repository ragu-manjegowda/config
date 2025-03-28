-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.define_keymap(client)
    local map = vim.keymap.set

    -- <c-x><c-o> is also mapped to <c-d> in options.lua via wildchar
    vim.opt.omnifunc = "v:lua.vim.lsp.omnifunc"

    if client:supports_method('textDocument/implementation') then
        map({ 'n', 'v' }, '<leader>lD', '<cmd>lua vim.lsp.buf.declaration()<CR>',
            { silent = true, desc = 'LSP goto declaration' })
    end

    if client:supports_method('textDocument/formatting') then
        map({ 'n', 'v' }, '<leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>',
            { silent = true, desc = 'LSP formatting' })
    end

    map('n', '<leader>ltv', function()
        local new_config = not vim.diagnostic.config().virtual_lines
        vim.diagnostic.config({ virtual_lines = new_config })
    end, { desc = 'Toggle diagnostic virtual_lines' })

    map('n', '<leader>lti', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = 'Toggle inlay hints' })
end

function M.setup_signatureHelp(client)
    local map = vim.keymap.set
    if client:supports_method('textDocument/signatureHelp') then
        local res, lsp_signature
        res, lsp_signature = pcall(require, "lsp_signature")
        if not res then
            vim.notify("lsp_signature not found", vim.log.levels.WARN)
        else
            lsp_signature.setup({
                doc_lines = 0,
                hint_enable = false,
                select_signature_key = "<M-n>"
            }, vim.api.nvim_get_current_buf())

            map({ 'n', 'i' }, '<C-k>',
                '<cmd>lua require("lsp_signature").toggle_float_win()<CR>',
                { silent = true, desc = 'Toggle LSP signature' })
        end
    end
end

function M.setup_diagnostics(client)
    if client:supports_method('textDocument/hover') then
        vim.lsp.buf.hover(
            { border = 'rounded' }
        )
    end

    local signs = {
        Error = "", Hint = "", Info = "", Information = "", Warn = "" }

    vim.diagnostic.config({
        float = {
            border = "rounded"
        },
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = signs.Error,
                [vim.diagnostic.severity.HINT] = signs.Hint,
                [vim.diagnostic.severity.INFO] = signs.Info,
                [vim.diagnostic.severity.WARN] = signs.Warn
            }
        }
    })
end

function M.setup_completionKind()
    local res, protocol = pcall(require, "vim.lsp.protocol")
    if not res then
        vim.notify("lsp.protocol not found", vim.log.levels.ERROR)
        return
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

vim.api.nvim_create_augroup("lsp attach", { clear = true })
vim.api.nvim_create_autocmd(
    { "LspAttach" },
    {
        group = "lsp attach",
        desc = "LSP on_attach",
        callback = function(args)
            local client = assert(
                vim.lsp.get_client_by_id(args.data.client_id))

            M.define_keymap(client)

            M.setup_signatureHelp(client)

            M.setup_diagnostics(client)

            M.setup_completionKind()

            if client:supports_method('textDocument/hover') then
                vim.lsp.buf.hover(
                    { border = 'rounded' }
                )
            end
        end,
    }
)


function M.config()
    local res, nvim_lsp, cmp_nvim_lsp, lsp_windows
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
    nvim_lsp.bashls.setup {}

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
        root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
        cmd = clangd_cmd
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Cmake
    nvim_lsp.cmake.setup {}

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

    if utils.is_bazel_project() then
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
    nvim_lsp.jsonls.setup {}

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Lua
    nvim_lsp.lua_ls.setup {
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
        capabilities = watch_capabilities
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

    -- nvim_lsp.pyright.setup {
    --     flags = {
    --         debounce_text_changes = 150,
    --     },
    --     settings = {
    --         python = {
    --             analysis = {
    --                 autoImportCompletions = false,
    --                 diagnosticMode = "openFilesOnly",
    --                 -- diagnosticSeverityOverrides = {
    --                 --     reportGeneralTypeIssues = "none",
    --                 --     reportOptionalMemberAccess = "none",
    --                 --     reportOptionalSubscript = "none",
    --                 --     reportPrivateImportUsage = "none",
    --                 -- },
    --                 useLibraryCodeForTypes = true
    --             },
    --             linting = { pylintEnabled = false }
    --         },
    --     },
    -- }

    -- Pylsp for hover, documentation, go to definition, syntax checking
    -- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
    nvim_lsp.pylsp.setup {
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
    -- Ruby
    nvim_lsp.ruby_lsp.setup {
        init_options = {
            formatter = 'standard',
            linters = { 'standard' }
        }
    }
    -- Need this for formatting
    -- https://github.com/standardrb/standard/wiki/IDE:-neovim
    nvim_lsp.standardrb.setup {
        single_file_support = true
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Rust
    nvim_lsp.rust_analyzer.setup {
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
        filetypes = { "html", "toml" },
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
    nvim_lsp.vimls.setup {}

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Toolchain of Web
    nvim_lsp.biome.setup {
        single_file_support = true
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Yaml
    nvim_lsp.yamlls.setup {}
end

return M
