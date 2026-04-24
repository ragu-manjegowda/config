-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

local ensure_installed = {
    "bash",
    "c",
    "cmake",
    "cpp",
    "css",
    "csv",
    "desktop",
    "devicetree",
    "diff",
    "dockerfile",
    "git_config",
    "git_rebase",
    "gitcommit",
    "gitignore",
    "go",
    "gomod",
    "gosum",
    "html",
    "htmldjango",
    "ini",
    "javascript",
    "json",
    "kconfig",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "muttrc",
    "php",
    "proto",
    "python",
    "query",
    "rasi",
    "regex",
    "requirements",
    "ruby",
    "rust",
    "ssh_config",
    "starlark",
    "textproto",
    "tmux",
    "toml",
    "tsx",
    "typescript",
    "udev",
    "usd",
    "vim",
    "vimdoc",
    "xml",
    "xresources",
    "yaml",
}

M.config = function()
    local ok, nts = pcall(require, "nvim-treesitter")
    if not ok then
        vim.notify("nvim-treesitter not found", vim.log.levels.ERROR)
        return
    end

    nts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })

    local cfg_ok, nts_cfg = pcall(require, "nvim-treesitter.config")
    if cfg_ok then
        local installed = nts_cfg.get_installed() or {}
        local to_install = vim.iter(ensure_installed)
            :filter(function(p) return not vim.tbl_contains(installed, p) end)
            :totable()
        if #to_install > 0 then
            pcall(nts.install, to_install)
        end
    end

    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),
        callback = function(args)
            if vim.bo[args.buf].filetype == "BigFile" then
                return
            end
            local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
            if not lang or not vim.treesitter.language.add(lang) then
                return
            end
            pcall(vim.treesitter.start, args.buf)
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
    })

    vim.keymap.set("n", "<M-/>", function()
        vim.cmd("normal! van")
    end, { silent = true, desc = "Treesitter: select parent node" })

    vim.keymap.set("x", "<M-/>", function()
        vim.cmd("normal! an")
    end, { silent = true, desc = "Treesitter: extend to parent node" })

    vim.keymap.set("x", "<bs>", function()
        vim.cmd("normal! in")
    end, { silent = true, desc = "Treesitter: shrink to child node" })

    local links = {
        ["@lsp.type.namespace"] = "@namespace",
        ["@lsp.type.type"] = "@type",
        ["@lsp.type.class"] = "@type",
        ["@lsp.type.enum"] = "@type",
        ["@lsp.type.interface"] = "@type",
        ["@lsp.type.struct"] = "@structure",
        ["@lsp.type.parameter"] = "@parameter",
        ["@lsp.type.variable"] = "@variable",
        ["@lsp.type.property"] = "@property",
        ["@lsp.type.enumMember"] = "@constant",
        ["@lsp.type.function"] = "@function",
        ["@lsp.type.method"] = "@method",
        ["@lsp.type.macro"] = "@macro",
        ["@lsp.type.decorator"] = "@function",
    }

    for newgroup, oldgroup in pairs(links) do
        vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
    end
end

return M
