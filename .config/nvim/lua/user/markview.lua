-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, markview = pcall(require, "markview")
    if not res then
        vim.notify("markview not found", vim.log.levels.ERROR)
        return
    end

    markview.setup({
        modes = { "c", "n", "no", "v" },
        callbacks = {
            on_enable = function(_, win)
                vim.wo[win].conceallevel = 2;
                vim.wo[win].concealcursor = "n";
            end
        }
    })
end

return M
