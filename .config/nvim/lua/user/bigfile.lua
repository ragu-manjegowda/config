-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.setup()
    local res, bigfile = pcall(require, "bigfile")
    if not res then
        vim.notify("bigfile not found", vim.log.levels.ERROR)
        return
    end

    local mini_indentscope = {
        name = "mini_indentscope",
        disable = function(buf)
            vim.api.nvim_buf_set_var(buf, "miniindentscope_disable", 1)
            require("gitsigns").detach(buf)
        end,
    }

    bigfile.config({
        filesize = 1,
        features = {
            "filetype",
            "indent_blankline",
            "lsp",
            "matchparen",
            mini_indentscope,
            "syntax",
            "treesitter",
            "vimopts"
        }
    })

    -- taken from AstroNvim
    local big_file_events = { "BufRead", "BufWinEnter", "BufNewFile" }
    vim.api.nvim_create_autocmd(big_file_events, {
        once = true,
        callback = function(args)
            local buftype = vim.api.nvim_get_option_value("buftype",
                { buf = args.buf })
            if not (vim.fn.expand "%" == "" or buftype == "nofile") then
                vim.cmd "do User FileOpened"
                require("user.lspconfig").config()
            end
        end
    })
end

return M
