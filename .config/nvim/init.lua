-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Load all static (non plugin based) settings
-------------------------------------------------------------------------------

local res, utils = pcall(require, "user.utils")
if not res then
    -- This is scary, basically user config bombs at this point!!
    vim.notify("Error loading user.utils", vim.log.levels.ERROR)
    return
end

local static_settings = {
    "user.options",
    "user.keymaps",
    "user.autocommands",
    "user.bufonly",
    "user.bigfile",
}

for _, entry in pairs(static_settings) do
    utils.load_plugin(entry, "setup")
end

-------------------------------------------------------------------------------
--- Load plugins
-------------------------------------------------------------------------------
-- Bootstrap Lazy
local lazy = utils.load_plugin("user.bootstrap", "init")
if lazy then
    -- Load plugins
    local res, plugins = utils.load_plugin("user.plugins-table")

    if res then
        res = utils.load_plugin("user.bootstrap", "load", plugins)
    end

    if not res then
        vim.notify("Error loading user.plugins-table", vim.log.levels.ERROR)
    end
end
