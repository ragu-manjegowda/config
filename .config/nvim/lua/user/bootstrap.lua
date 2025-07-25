-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.init()
    -- Lazy.nvim's install path
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

    -- Install lazy if not installed yet.
    -- https://neovim.io/doc/user/luvref.html#uv.fs_stat()
    ---@diagnostic disable-next-line: undefined-field
    if not vim.uv.fs_stat(lazypath) then
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath,
        })
    end

    -- Add lazy to runtime path
    vim.opt.rtp:prepend(lazypath)
end

function M.load(plugins)
    -- Check if lazy is installed.
    local lazy_available, lazy = pcall(require, "lazy")
    if not lazy_available then
        print "Skipping loading plugins until Lazy is installed"
        return
    end

    -- If opening from inside neovim terminal then do not load all the
    -- other plugins
    if os.getenv("NVIM") ~= nil then
        lazy.setup {
            { "willothy/flatten.nvim", config = true },
        }
        return
    end

    local opts = {
        defauls = {
            lazy = true
        },
        diff = {
            cmd = "diffview.nvim"
        },
        install = {
            -- try to load one of these colorschemes when starting an installation during startup
            colorscheme = { "solarized" }
        },
        ui = {
            border = "rounded"
        }
    }

    -- Load plugins
    local status_ok, _ = xpcall(function()
        lazy.setup(plugins, opts)
    end, debug.traceback)

    -- Defer status checking until after lazy is installed.
    if not status_ok then
        print "Problems detected while loading plugins' configurations"
    end
end

return M
