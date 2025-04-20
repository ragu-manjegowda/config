-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-- reference    : https://github.com/folke/snacks.nvim
-------------------------------------------------------------------------------

---@class BigFile
local M = {}

M.meta = {
    desc = "Deal with big files",
    needs_setup = true,
}

--- Set buffer-local options.
---@param bo vim.bo|{}
function M.bo(bo)
    for k, v in pairs(bo or {}) do
        vim.api.nvim_set_option_value(k, v, { scope = "local" })
    end
end

function M.setup()
    local opts = {
        notify = true,            -- show notification when big file detected
        size = 1.5 * 1024 * 1024, -- 1.5MB
        line_length = 5000,       -- average line length
        -- Enable or disable features when big file detected
        ---@param ctx {buf: number, ft:string}
        setup = function(ctx)
            if vim.fn.exists(":NoMatchParen") ~= 0 then
                vim.cmd([[NoMatchParen]])
            end

            M.bo({
                foldmethod = "manual",
                statuscolumn = "",
                conceallevel = 0
            })

            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(ctx.buf) then
                    vim.bo[ctx.buf].syntax = ctx.ft

                    -- Disable git signs
                    local res, gitsigns = pcall(require, "gitsigns")
                    if res then
                        gitsigns.detach(ctx.buf)
                    end
                end
            end)
        end
    }

    vim.filetype.add({
        pattern = {
            [".*"] = {
                function(path, buf)
                    if not path or not buf or vim.bo[buf].filetype == "BigFile" then
                        return
                    end
                    if path ~= vim.api.nvim_buf_get_name(buf) then
                        return
                    end
                    local size = vim.fn.getfsize(path)
                    if size <= 0 then
                        return
                    end
                    if size > opts.size then
                        return "BigFile"
                    end
                    local lines = vim.api.nvim_buf_line_count(buf)
                    return lines > opts.line_length and "BigFile" or nil
                end,
            },
        },
    })

    vim.api.nvim_create_autocmd({ "FileType" }, {
        callback = function(ev)
            if opts.notify then
                local path = vim.fn.fnamemodify(
                    vim.api.nvim_buf_get_name(ev.buf), ":p:~:.")

                local msg = {
                    ("Big file detected `%s`."):format(path),
                    "Some Neovim features have been **disabled**.",
                }

                vim.notify(
                    table.concat(msg, "\n"),
                    {
                        title = "Big File",
                        level = vim.log.levels.WARN
                    }
                )
            end

            vim.api.nvim_buf_call(ev.buf, function()
                opts.setup({
                    buf = ev.buf,
                    ft = vim.filetype.match({ buf = ev.buf }) or "",
                })
            end)
        end,
        group = vim.api.nvim_create_augroup("BigFile", { clear = true }),
        pattern = "BigFile"
    })
end

return M
