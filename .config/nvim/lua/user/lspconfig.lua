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

local lspconfig
res, lspconfig = pcall(require, "lspconfig")
if not res then
    vim.notify("lspconfig not found", vim.log.levels.ERROR)
    return
end

-- Keymap options
-- @param desc string
-- @param bufnr number | nil
-- @return table
local opts = function(desc, bufnr)
    return {
        buffer = bufnr,
        desc = "lsp: " .. desc
    }
end

-- LSP attach keymaps
---@param client vim.lsp.Client
---@param bufnr number
---@return nil
function M.define_lsp_attach_keymap(client, bufnr)
    -- <c-x><c-o> is also mapped to <c-d> in options.lua via wildchar
    vim.opt.omnifunc = "v:lua.vim.lsp.omnifunc"

    if client:supports_method("textDocument/implementation") then
        utils.keymap({ "n", "v" }, "<leader>lD",
            "<cmd>lua vim.lsp.buf.declaration()<CR>",
            opts('LSP goto declaration', bufnr))
    end

    if client:supports_method("textDocument/formatting") then
        utils.keymap({ "n", "v" }, "<leader>lf",
            "<cmd>lua vim.lsp.buf.format()<CR>",
            opts('LSP formatting', bufnr))
    end
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

            M.define_lsp_attach_keymap(client, args.buf)
        end,
    }
)

-- Setup diagnostics config
---@return nil
function M.setup_diagnostics()
    local signs = {
        Error = "",
        Hint = "",
        Info = "",
        Information = "",
        Warn = ""
    }

    vim.diagnostic.config({
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = signs.Error,
                [vim.diagnostic.severity.HINT] = signs.Hint,
                [vim.diagnostic.severity.INFO] = signs.Info,
                [vim.diagnostic.severity.WARN] = signs.Warn
            }
        },
        virtual_lines = {
            current_line = true,
            severity = {
                min = vim.diagnostic.severity.ERROR,
            }
        }
    })

    utils.keymap("n", "<leader>ltv", function()
            local new_config = not vim.diagnostic.config().virtual_lines
            vim.diagnostic.config({ virtual_lines = new_config })
        end,
        opts('Toggle diagnostic virtual_lines'))
end

-- Setup CompletionItemKind
---@return nil
function M.setup_completionKind()
    local protocol
    res, protocol = pcall(require, "vim.lsp.protocol")
    if not res then
        vim.notify("lsp.protocol not found", vim.log.levels.ERROR)
        return
    end

    protocol.CompletionItemKind = {
        "", -- Text
        "", -- Method
        "", -- Function
        "", -- Constructor
        "", -- Field
        "", -- Variable
        "", -- Class
        "ﰮ", -- Interface
        "", -- Module
        "", -- Property
        "", -- Unit
        "", -- Value
        "", -- Enum
        "", -- Keyword
        "﬌", -- Snippet
        "", -- Color
        "", -- File
        "", -- Reference
        "", -- Folder
        "", -- EnumMember
        "", -- Constant
        "", -- Struct
        "", -- Event
        "ﬦ", -- Operator
        "", -- TypeParameter
    }
end

function M.setup_inlayHints()
    vim.lsp.inlay_hint.enable()

    utils.keymap("n", "<leader>lti", function()
            local new_config = not vim.lsp.inlay_hint.is_enabled()
            vim.lsp.inlay_hint.enable(new_config)
        end,
        opts('Toggle inlay hints'))
end

-- Get default config, merge cmp capabilities if available
---@return table
function M.get_default_config()
    local blink_cmp, lsp_defaults

    lsp_defaults = lspconfig.util.default_config

    res, blink_cmp = pcall(require, "blink.cmp")
    if not res then
        vim.notify("blink.cmp not found", vim.log.levels.WARN)
    else
        lsp_defaults.capabilities =
            vim.tbl_deep_extend(
                "force",
                lsp_defaults.capabilities,
                blink_cmp.get_lsp_capabilities({}, false))
    end

    return lsp_defaults
end

-- Get Markdown LSP setup config
---@return table
function M.markdown_setup()
    local default_config = M.get_default_config()

    -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
    -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
    local watch_capabilities = vim.tbl_deep_extend(
        "force",
        default_config.capabilities,
        {
            workspace = {
                didChangeWatchedFiles = {
                    dynamicRegistration = true,
                },
            },
        }
    )

    return {
        capabilities = watch_capabilities
    }
end

-- Get Golang LSP setup config
---@return table
function M.gopls_setup()
    -- Golang
    -- https://github.com/bazelbuild/rules_go/wiki/Editor-setup
    -- https://github.com/AnatoleLucet/dotfiles/blob/9f329f8d624655ab262329e12531eb1dfb54df15/nvim.save/.config/nvim/lua/lsp/init.lua#L153

    local cwd = vim.fn.getcwd()

    local gopackagesdriver = ""
    local bazel_workspace_dir = ""
    local goroot = ""

    if utils.is_bazel_project() then
        gopackagesdriver = cwd .. "/scripts/gopackagesdriver.sh"
        if vim.fn.filereadable(gopackagesdriver) ~= 1 then
            gopackagesdriver = ""
        end

        goroot = cwd .. "/bazel-" .. cwd:match("/([^/]*)$") .. "/external/go_sdk"
        if vim.fn.isdirectory(goroot) ~= 1 then
            goroot = ""
        end

        bazel_workspace_dir = vim.fn.fnamemodify(cwd, ":t")
    end

    return {
        flags = {
            debounce_text_changes = 150,
        },
        cmd = { "gopls", "serve" },
        filetypes = { "go", "gomod" },
        root_dir = lspconfig.util.root_pattern("go.mod", ".gitignore"),
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
end

-- Get Clangd LSP setup config
---@return table
function M.clangd_setup()
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

    return {
        root_dir = lspconfig.util.root_pattern(
            "compile_commands.json", ".gitignore"),
        cmd = clangd_cmd
    }
end

-- Define LSP servers to be setup
---@return table
function M.servers_opts()
    return {
        servers = {
            bashls = {},
            biome = {
                single_file_support = true
            },
            clangd = M.clangd_setup(),
            cmake = {},
            gopls = M.gopls_setup(),
            harper_ls = {
                filetypes = { "html", "toml" },
                settings = {
                    ["harper-ls"] = {
                        linters = {
                            spell_check = false,
                            sentence_capitalization = false,
                        },
                    }
                }
            },
            jsonls = {},
            lua_ls = {
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
            },
            marksman = M.markdown_setup(),
            pylsp = {
                flags = {
                    debounce_text_changes = 150
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
                                    "C0103", "E266",
                                    "W0104", "W391", "W503", "W504"
                                },
                                maxLineLength = 80
                            },
                            pydocstyle = { enabled = true },
                            pyflakes = { enabled = false }
                        }
                    }
                }
            },
            ruby_lsp = {
                init_options = {
                    formatter = "standard",
                    linters = { "standard" }
                }
            },
            rust_analyzer = {
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
            },
            -- Need this for formatting
            -- https://github.com/standardrb/standard/wiki/IDE:-neovim
            standardrb = {
                single_file_support = true
            },
            vimls = {},
            yamlls = {}
        }
    }
end

-- Enable lsp via lspconfig
---@return nil
function M.enable_with_lspconfig()
    lspconfig.util.default_config = M.get_default_config()

    local servers_opts = M.servers_opts()
    for server, config in pairs(servers_opts.servers) do
        lspconfig[server].setup(config)
    end
end

-- Enable lsp via native lsp (not available with lspconfig)
---@return nil
function M.enable_with_vim_lsp()
    local servers = {
        tmuxls = {
            cmd = { "tmux-language-server" },
            filetypes = { "tmux" }
        },
        neomuttls = {
            cmd = { "mutt-language-server" },
            filetypes = { "muttrc", "neomuttrc" }
        }
    }

    for server, config in pairs(servers) do
        vim.lsp.config[server] = config
        vim.lsp.enable(server)
    end
end

function M.config()
    -- Setup CompletionItemKind irrespective of `lspconfig`
    M.setup_completionKind()

    -- Setup diagnostics irrespective of `lspconfig`
    M.setup_diagnostics()

    M.enable_with_lspconfig()

    M.enable_with_vim_lsp()

    M.setup_inlayHints()
end

return M
