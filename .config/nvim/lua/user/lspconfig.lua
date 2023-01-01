local vim = vim

local M = {}

local res, protocol = pcall(require, "vim.lsp.protocol")
if not res then
    vim.notify("lsp.protocol not found", vim.log.levels.ERROR)
    return
end

local signs = { Error = "", Hint = "", Info = "", Information = "", Warn = "" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = "", numhl = "" })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local function on_attach(client, bufnr)

    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    -- <c-x><c-o> is also mapped to <c-d> in nvim-cmp
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    buf_set_keymap('n', '<leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>',
                   { silent = true, desc = 'LSP formatting' })
    buf_set_keymap('v', '<leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>',
                   { silent = true, desc = 'LSP range formatting' })

    -- Pyright for completion, rename, type checking and
    -- Pylsp for hover, documentation, go to definition, syntax checking
    local rc = client.server_capabilities

    if client.name == 'pyright' then
        rc.hover = false
    end

    if client.name == 'pylsp' then
        rc.rename = false
        rc.signature_help = false
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
    local nvim_lsp, cmp_nvim_lsp
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

    local lsp_defaults = nvim_lsp.util.default_config

    lsp_defaults.capabilities =
        vim.tbl_deep_extend(
        'force',
        lsp_defaults.capabilities,
        cmp_nvim_lsp.default_capabilities())

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
        "-j=4",
        "--pch-storage=memory",
        "--use-dirty-headers",
        -- You MUST set this arg ↓ to your clangd executable location (if not included)!
        -- "--query-driver=/usr/bin/clang++,/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
    }

    if not vim.fn.has("macunix") then
        -- Linux specific exclude this on macunix
        table.insert(clangd_cmd, "--enable-config")
        table.insert(clangd_cmd, "--malloc-trim")
    end

    local clangd_extensions
    res, clangd_extensions = pcall(require, "clangd_extensions")
    if not res then
        vim.notify("clangd_extensions not found", vim.log.levels.ERROR)
        return
    end

    clangd_extensions.setup {
        server = {
            on_attach = on_attach,
            root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
            cmd = clangd_cmd,
        },
        extensions = {
            symbol_info = {
                border = "rounded",
            },
        }
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
    nvim_lsp.gopls.setup {
        on_attach = on_attach,
        cmd = { "gopls", "serve" },
        filetypes = { "go", "gomod" },
        root_dir = nvim_lsp.util.root_pattern("go.mod", ".gitignore"),
        settings = {
            gopls = {
                analyses = {
                    unusedparams = true,
                },
                staticcheck = true,
            },
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
    nvim_lsp.sumneko_lua.setup {
        on_attach = on_attach,
        -- root_dir is .luacheckrc which is added for both awesome and nvim
        cmd = { "lua-language-server", "--preview" },
        settings = {
            Lua = {
                telemetry = { enable = false },
                completion = { callSnippet = "Replace" },
            }
        }
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Python
    -- https://www.reddit.com/r/neovim/comments/sazbw6/comment/hw1s6qg/?utm_source=share&utm_medium=web2x&context=3
    -- Pyright for completion, rename, type checking

    -- Set heap size to 4GB - https://github.com/microsoft/pyright/issues/3239
    vim.env.NODE_OPTIONS = "--max-old-space-size=4096"

    nvim_lsp.pyright.setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        settings = {
            python = {
                analysis = {
                    useLibraryCodeForTypes = true,
                    diagnosticSeverityOverrides = {
                        reportGeneralTypeIssues = "none",
                        reportOptionalMemberAccess = "none",
                        reportOptionalSubscript = "none",
                        reportPrivateImportUsage = "none",
                    },
                    autoImportCompletions = false,
                },
                linting = { pylintEnabled = false }
            },
        },
    }

    -- Pylsp for hover, documentation, go to definition, syntax checking
    nvim_lsp.pylsp.setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        settings = {
            pylsp = {
                builtin = {
                    installExtraArgs = {
                        'flake8', 'pycodestyle', 'pydocstyle',
                        'pyflakes', 'pylint', 'yapf'
                    },
                },
                plugins = {
                    jedi_completion = { enabled = false },
                    rope_completion = { enabled = false },
                    flake8 = { enabled = false },
                    pyflakes = { enabled = false },
                    pycodestyle = {
                        ignore = {
                            'C0103', 'E226', 'E266', 'E302', 'E303',
                            'E304', 'E305', 'E402', 'E501',
                            'W0104', 'W0621', 'W391', 'W503', 'W504'
                        }
                    },
                },
            },
        },
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Rust
    nvim_lsp.rust_analyzer.setup {
        on_attach = on_attach
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
