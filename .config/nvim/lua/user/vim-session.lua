-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    -- Configure vim-session

    -- Options suggested in https://github.com/rmagatti/auto-session
    local session_options = "blank,buffers,curdir,folds,help,tabpages,winsize"
    session_options = session_options .. ",winpos,terminal,localoptions"
    vim.o.sessionoptions = session_options

    -- Create directory for vim-session if it does not exist
    local session_directory = vim.fn.stdpath("data") .. "/sessions"
    vim.g.session_directory = session_directory
    if not vim.fn.isdirectory(session_directory) then
        vim.call(vim.fn.mkdir(session_directory, "p"))
    end

    -- Don't autoload sessions on startup
    vim.g.session_autoload = "no"

    -- Don't prompt to save on exit
    vim.g.session_autosave = "yes"

    vim.g.session_autosave_periodic = 1
    vim.g.session_autosave_silent = 1
    vim.g.session_verbose_messages = 0
    vim.g.session_command_aliases = 1
    vim.g.session_menu = 0
    vim.g.session_extension = ''

    -- vim.g.session_autosave_to will be set  in utils.lua
end

return M
