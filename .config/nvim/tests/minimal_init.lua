-- Minimal init for testing
-- This file provides a minimal Neovim setup for running tests

-- Add nvim config to runtime path
vim.opt.runtimepath:prepend(vim.fn.expand("~/.config/nvim"))

-- Set up package path for user modules
package.path = vim.fn.expand("~/.config/nvim/lua/?.lua") .. ";" .. 
               vim.fn.expand("~/.config/nvim/lua/?/init.lua") .. ";" .. 
               package.path

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.runtimepath:prepend(lazypath)

-- Install plenary.nvim if not present (for CI)
local plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "--depth=1",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_path
    })
end

-- Load lazy and all plugins
if vim.fn.isdirectory(lazypath) == 1 then
    -- Set mapleader before lazy
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
    
    -- Add all lazy-installed plugins to runtimepath
    local lazy_plugins = vim.fn.stdpath("data") .. "/lazy"
    if vim.fn.isdirectory(lazy_plugins) == 1 then
        for _, plugin_dir in ipairs(vim.fn.readdir(lazy_plugins)) do
            local plugin_path = lazy_plugins .. "/" .. plugin_dir
            if vim.fn.isdirectory(plugin_path) == 1 then
                vim.opt.runtimepath:append(plugin_path)
            end
        end
    end
    
    -- Load lazy
    local lazy_ok, lazy = pcall(require, "lazy")
    if lazy_ok then
        -- Lazy is loaded, plugins are now available
    end
end

-- Disable unnecessary plugins during testing
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Minimal vim options for testing
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

print("Minimal init loaded for testing")

