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
vim.opt.runtimepath:prepend(vim.fn.expand("~/.config/nvim"))

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.runtimepath:prepend(lazypath)

-- Install plenary.nvim if not present (for CI)
local plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
    print("Installing plenary.nvim for testing...")
    vim.fn.system({
        "git",
        "clone",
        "--depth=1",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_path
    })
end
vim.opt.runtimepath:prepend(plenary_path)

-- Set up package path for user modules and test helpers
local nvim_config = vim.fn.expand("~/.config/nvim")
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
