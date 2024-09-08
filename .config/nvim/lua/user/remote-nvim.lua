-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, remote_nvim = pcall(require, "remote-nvim")
    if not res then
        vim.notify("remote-nvim not found", vim.log.levels.ERROR)
        return
    end

    remote_nvim.setup({
        ssh_config = {
            -- Binary to use for running SSH copy commands
            scp_binary = "rsync -avz --no-perms --no-owner --no-group --no-links",
        }
    })
end

return M
