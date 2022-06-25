local M = {}

local path_sep = "/"

function join_paths(...)
  local result = table.concat({ ... }, path_sep)
  return result
end

function get_config_dir()
    return vim.fn.stdpath "config"
end

local compile_path = join_paths(get_config_dir(), "plugin", "packer_compiled.lua")

function run_on_packer_complete()
    vim.cmd [[doautocmd User PackerComplete]]
end

function M.init()
    opts = {}

    local install_path =
        join_paths(vim.fn.stdpath "data", "site", "pack", "packer",
                   "start", "packer.nvim")

    local init_opts = {
        package_root = join_paths(vim.fn.stdpath "data", "site", "pack"),
        compile_path = compile_path,
        git = {
            clone_timeout = 300,
        },
        display = {
            open_fn = function()
                return require("packer.util").float { border = "rounded" }
            end,
        },
    }

    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
        vim.fn.system { "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path }
        vim.cmd "packadd packer.nvim"
    end

    local status_ok, packer = pcall(require, "packer")
    if status_ok then
        packer.on_complete = vim.schedule_wrap(function()
            run_on_packer_complete()
        end)
        packer.init(init_opts)
    end
end

function M.load(plugins)
    local packer_available, packer = pcall(require, "packer")
    if not packer_available then
        print "skipping loading plugins until Packer is installed"
        return
    end
    local status_ok, _ = xpcall(function()
        packer.reset()
        packer.startup(function(use)
            for _, plugin in ipairs(plugins) do
                use(plugin)
            end
        end)
    end, debug.traceback)
    if not status_ok then
        print "problems detected while loading plugins' configurations"
    end
end

return M
