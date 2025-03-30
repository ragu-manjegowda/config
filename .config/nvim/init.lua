-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Load all static (non plugin based) settings
require "user.options"
require "user.keymaps"
require "user.autocommands"
require "user.colorscheme"
require "user.buf-only"

-- Bootstrap Lazy
local res, bootstrap = pcall(require, "user.bootstrap")
if not res then
    vim.notify("Not able to bootstrap Lazy", vim.log.levels.WARN)
else
    bootstrap.init()

    -- Load plugins
    local plugins

    res, plugins = pcall(require, "user.plugins-table")
    if not res then
        vim.notify("Plugins table not found", vim.log.levels.WARN)
    else
        bootstrap.load { plugins }
    end
end

