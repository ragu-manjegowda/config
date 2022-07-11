local vim = vim

local M = {}

local protocol = require'vim.lsp.protocol'

local signs = { Error = " ", Warn = " ", Hint = " ", Information = " " }
for type, icon in pairs(signs) do
    local hl = "LspDiagnosticsSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local function on_attach(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
    --Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }

    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', '<leader>pe', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '[e', '<cmd> lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']e', '<cmd> lua vim.diagnostic.goto_next()<CR>', opts)

    -- See `:help vim.lsp.*` for documentation on any of the below functions
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

local log_path = vim.fn.expand('~/.config/nvim/misc/ccls/ccls.log')
local cache_dir = vim.fn.expand('~/.config/nvim/misc/ccls')

vim.lsp.handlers["textDocument/publishDiagnostics"]  = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = false,
        virtual_text = false
  }
)

function M.config()
    local nvim_lsp = require('lspconfig')

    nvim_lsp.ccls.setup {
        on_attach = on_attach,
        filetypes = { "c", "cpp", "h", "hpp" },
        root_dir = nvim_lsp.util.root_pattern("compile_commands.json", ".gitignore"),
        cmd = {
            -- 'clangd',
            -- '--background-index',
            -- '--clang-tidy',
            -- '-j=16',
            -- '--log=info'
            'ccls',
            '--log-file='..log_path,
            '-v=1',
            '--init={"index": {"blacklist":[".git", "data/*", \
                     "bazel-*", "partners/", "avddn/", "apps/", "av/", \
                     "benchmarks/", "ci/", "doc/", "private/", "resources/", \
                     "scripts", "share", "swig/", "ux", \
                     "dazel-out", "lib*.so", \
                     "preFlightChecker", "pilotnet", "tools/experimental/maps", \
                     "tools/experimental/localization_metrics"]}}'
        },
        init_options = {
            cache = { directory = cache_dir; };
            index = { threads = 3; };
            client = { snippetSupport = true; };
            clang = { extraArgs = { "-Wno-extra", "-Wno-empty-body" }; };
            completion = { detailedLabel = false; caseSensitivity = 1; };
        },
        capabilities = capabilities
    }

    nvim_lsp.rust_analyzer.setup {
        on_attach = on_attach,
        capabilities = capabilities
    }
end

return M


