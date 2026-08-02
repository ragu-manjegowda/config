-------------------------------------------------------------------------------
-- Minimal init for testing plugin configurations
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
--
-- Usage:
--   nvim --headless -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
-------------------------------------------------------------------------------

-- Suppress ALL notifications during tests FIRST (before any modules load)
-- This prevents "not found" messages from cluttering test output
vim.notify = function(_, _, _) end

-- Set mapleader before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable unnecessary plugins during testing
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Minimal vim options for testing
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false

-- Reduce timeout for faster tests
vim.opt.timeoutlen = 100
vim.opt.updatetime = 100

-- Add nvim config to runtime path
local nvim_config = vim.fn.stdpath("config")
vim.opt.runtimepath:prepend(nvim_config)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.runtimepath:prepend(lazypath)

local lazy_plenary = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
local vendor_plenary = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"
local plenary_path = lazy_plenary
if vim.fn.isdirectory(lazy_plenary) == 0 then
    plenary_path = vendor_plenary
end
if vim.fn.isdirectory(plenary_path) == 0 then
    print("Installing plenary.nvim for testing...")
    vim.fn.mkdir(vim.fs.dirname(vendor_plenary), "p")
    local output = vim.fn.system({
        "git",
        "clone",
        "--depth=1",
        "https://github.com/nvim-lua/plenary.nvim",
        vendor_plenary
    })
    if vim.v.shell_error ~= 0 or vim.fn.isdirectory(vendor_plenary) == 0 then
        error("Failed to install plenary.nvim: " .. output)
    end
end
vim.opt.runtimepath:prepend(plenary_path)

-- Set up package path for user modules and test helpers
package.path = nvim_config .. "/?.lua;" ..
    nvim_config .. "/?/init.lua;" ..
    nvim_config .. "/lua/?.lua;" ..
    nvim_config .. "/lua/?/init.lua;" ..
    package.path

-- Add all lazy-installed plugins to runtimepath and package.path
local lazy_plugins = vim.fn.stdpath("data") .. "/lazy"
if vim.fn.isdirectory(lazy_plugins) == 1 then
    for _, plugin_dir in ipairs(vim.fn.readdir(lazy_plugins)) do
        local plugin_path = lazy_plugins .. "/" .. plugin_dir
        if vim.fn.isdirectory(plugin_path) == 1 then
            vim.opt.runtimepath:append(plugin_path)
            local lua_path = plugin_path .. "/lua"
            if vim.fn.isdirectory(lua_path) == 1 then
                package.path = lua_path .. "/?.lua;" ..
                    lua_path .. "/?/init.lua;" ..
                    package.path
            end
        end
    end
end

print("Minimal init loaded for testing")
