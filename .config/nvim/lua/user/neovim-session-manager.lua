-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, session_manager = pcall(require, "session_manager")
    if not res then
        vim.notify("session_manager not found", vim.log.levels.ERROR)
        return
    end

    local config
    res, config = pcall(require, "session_manager.config")
    if not res then
        vim.notify("session_manager config not found", vim.log.levels.ERROR)
        return
    end

    session_manager.setup({
        -- Define what to do when Neovim is started without arguments. See "Autoload mode" section below.
        autoload_mode = config.AutoloadMode.Disabled,
        -- All buffers of these file types will be closed before the session is saved.
        autosave_ignore_filetypes = {
            "fugitive",
            "gitcommit",
            "gitrebase"
        }
    })
end

return M
