local M = {}

function M.config()

    require("mason").setup({
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
