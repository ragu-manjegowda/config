-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()

    local res, mason = pcall(require, "mason")
    if not res then
        vim.notify("mason not found", vim.log.levels.ERROR)
        return
    end

    mason.setup({
        pip = {
            upgrade_pip = true,
        },
        log_level = vim.log.levels.INFO,
        ui = {
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗"
            },
            border = "rounded",
        }
    })

end

return M
