-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- References
-- https://github.com/zhuorantan/dotfiles
-- https://github.com/LunarVim/LunarVim

-- Load all static (non plugin based) settings
require "user.options"
require "user.keymaps"
require "user.autocommands"
require "user.colorscheme"
require "user.buf-only"

-- other way is to put the above in custom directory and make package of
-- its own vim.opt.rtp:append(vim.fn.stdpath "config" .. "/custom")
-- https://github.com/NvChad/NvChad/issues/605#issuecomment-1001109229

-- Bootstrap packer
local res, bootstrap = pcall(require, "user.bootstrap")
if not res then
    vim.notify("Bootstrapping not available", vim.log.levels.ERROR)
    return
end

bootstrap.init()

-- Load plugins
local plugins

res, plugins = pcall(require, "user.plugins-table")
if not res then
    vim.notify("Plugins table not found", vim.log.levels.ERROR)
    return
end

bootstrap.load { plugins }
