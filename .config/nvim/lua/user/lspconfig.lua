local vim = vim

local M = {}

local protocol = require'vim.lsp.protocol'

local signs = { Error = " ", Warn = " ", Hint = " ", Information = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = "", numhl = "" })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local function on_attach(_, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
    --Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', '<leader>ep', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '[e', '<cmd> lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']e', '<cmd> lua vim.diagnostic.goto_next()<CR>', opts)

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gA', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.preselectSupport = true
    capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
    capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
    capabilities.textDocument.completion.completionItem.deprecatedSupport = true
    capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
    capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
    capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
            'documentation',
            'detail',
            'additionalTextEdits',
        }
    }

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

-- local log_path = vim.fn.expand('~/.cache/nvim/ccls.log')
-- local cache_dir = vim.fn.expand('~/.cache/nvim/ccls')

vim.lsp.handlers["textDocument/publishDiagnostics"]  = vim.lsp.with(
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
  {border = 'rounded'}
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {border = 'rounded'}
)

function M.config()
    local nvim_lsp = require('lspconfig')

    ---------------------------------------------------------------------------
    -- Switch to clangd to benefit from the advantages, keeping this for a
    -- while till clangd setup becomes stable
    ---------------------------------------------------------------------------

    -- nvim_lsp.ccls.setup {
    --     on_attach = on_attach,
    --     filetypes = { "c", "cpp", "h", "hpp" },
    --     root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
    --     cmd = {
    --         -- 'clangd',
    --         -- '--background-index',
    --         -- '--clang-tidy',
    --         -- '-j=16',
    --         -- '--log=info'
    --         'ccls',
    --         '--log-file='..log_path,
    --         '-v=1',
    --         '--init={"index": {"blacklist":[".git", "data/*", \
    --                  "bazel-*", "partners/", "avddn/", "apps/", "av/", \
    --                  "benchmarks/", "ci/", "doc/", "private/", "resources/", \
    --                  "scripts", "share", "swig/", "ux", \
    --                  "dazel-out", "lib*.so", \
    --                  "preFlightChecker", "pilotnet", "tools/experimental/maps", \
    --                  "tools/experimental/localization_metrics"]}}'
    --     },
    --     init_options = {
    --         cache = { directory = cache_dir; };
    --         index = { threads = 3; };
    --         client = { snippetSupport = true; };
    --         clang = { extraArgs = { "-Wno-extra", "-Wno-empty-body" }; };
    --         completion = { detailedLabel = false; caseSensitivity = 1; };
    --     },
    --     capabilities = capabilities
    -- }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Bash
    nvim_lsp.bashls.setup {
        on_attach = on_attach,
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- C, C++
    require("clangd_extensions").setup {
        server = {
            on_attach = on_attach,
            capabilities = capabilities,
            root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
            cmd = {
                "clangd",
                "--all-scopes-completion=true",
                "--background-index",
                "--background-index-priority=low",
                "--clang-tidy",
                "--completion-style=detailed",
                "--enable-config",
                "--function-arg-placeholders",
                "--header-insertion=never",
                "-j=4",
                "--malloc-trim",
                "--pch-storage=memory",
                "--use-dirty-headers",
                -- You MUST set this arg ↓ to your clangd executable location (if not included)!
                -- "--query-driver=/usr/bin/clang++,/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
            },
        },
        extensions = {
            symbol_info = {
                border = "rounded",
            },
        },
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Cmake
    nvim_lsp.cmake.setup {
        on_attach = on_attach,
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Golang
    nvim_lsp.gopls.setup {
        on_attach = on_attach,
        cmd = {"gopls", "serve"},
        filetypes = {"go", "gomod"},
        root_dir = nvim_lsp.util.root_pattern("go.mod", ".gitignore"),
        settings = {
            gopls = {
                analyses = {
                    unusedparams = true,
                },
                staticcheck = true,
            },
        },
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Lua
    local runtime_path = vim.split(package.path, ";")
    table.insert(runtime_path, "lua/?.lua")
    table.insert(runtime_path, "lua/?/init.lua")

    nvim_lsp.sumneko_lua.setup {
        on_attach = on_attach,
        -- root_dir is .luacheckrc which is added for both awesome and nvim
        cmd = { "lua-language-server", "--preview" },
        settings = {
            Lua = {
                telemetry = { enable = false },
                runtime = {
                    -- LuaJIT in the case of Neovim
                    version = "LuaJIT",
                    path = runtime_path,
                },
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = {
                        "vim",
                        "capabilities",  -- lspconfig
                        "root",          -- awesomeWM
                        "awesome",       -- awesomeWM
                        "screen",        -- awesomeWM
                        "client",        -- awesomeWM
                        "clientkeys",    -- awesomeWM
                        "clientbuttons", -- awesomeWM
                        "startup",       -- awesomeWM
                        "message",       -- awesomeWM
                    },
                    disable = {
                        -- -- Need check nil
                        -- "need-check-nil",
                        -- -- This function requires 2 argument(s) but instead it is receiving 1
                        -- "missing-parameter",
                        -- -- Cannot assign `unknown` to `string`.
                        -- "assign-type-mismatch",
                        -- -- Cannot assign `unknown` to parameter `string`.
                        -- "param-type-mismatch",
                        -- -- This variable is defined as type `string`. Cannot convert its type to `unknown`.
                        -- "cast-local-type",
                    }
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = {
                        [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                        [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                    }
                },
                -- disable certain warnings that don't concern us
                -- https://github.com/sumneko/lua-language-server/blob/master/doc/en-us/config.md
                type = {
                    -- Cannot assign `string|nil` to parameter `string`.
                    weakNilCheck = true,
                    weakUnionCheck = true,
                    -- Cannot assign `number` to parameter `integer`.
                    castNumberToInteger = true,
                },
            }
        },
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Python
    nvim_lsp.pyright.setup{
        on_attach = on_attach,
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Rust
    nvim_lsp.rust_analyzer.setup {
        on_attach = on_attach,
        capabilities = capabilities
    }

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Vim
    nvim_lsp.vimls.setup {
        on_attach = on_attach,
        capabilities = capabilities
    }

end

return M


