-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

-- Patch opencode session module to pass cwd for non-git directories
-- This fixes session listing/resuming for non-git projects
function M.patch_session_for_non_git()
    local session = require("opencode.session")
    local state = require("opencode.state")
    local util = require("opencode.util")
    local Promise = require("opencode.promise")

    -- Store original function
    local original_get_all_workspace_sessions = session.get_all_workspace_sessions

    -- Override get_all_workspace_sessions to pass directory for non-git projects
    session.get_all_workspace_sessions = Promise.async(function()
        local cwd = vim.fn.getcwd()

        -- For non-git projects, pass the directory to the API
        if not util.is_git_project() then
            local sessions = state.api_client:list_sessions(cwd):await()
            if not sessions then
                return nil
            end

            table.sort(sessions, function(a, b)
                return a.time.updated > b.time.updated
            end)

            -- Filter sessions by workspace matching cwd
            sessions = vim.tbl_filter(function(s)
                if s.workspace and vim.startswith(cwd, s.workspace) then
                    return true
                end
                -- Also match if session directory matches cwd
                if s.directory and s.directory == cwd then
                    return true
                end
                return false
            end, sessions)

            return sessions
        end

        -- For git projects, use original behavior
        return original_get_all_workspace_sessions():await()
    end)

    -- Also patch create_session to pass directory for non-git projects
    local api_client_meta = getmetatable(state.api_client) or {}
    local original_create_session = api_client_meta.__index and
        api_client_meta.__index.create_session or
        state.api_client.create_session

    if original_create_session then
        local OpencodeApiClient = require("opencode.api_client")

        -- Store reference to original method from prototype
        local orig_create = OpencodeApiClient.new().__index and
            OpencodeApiClient.new().create_session

        -- We need to wrap the api_client's create_session
        local original_api_create = state.api_client.create_session

        state.api_client.create_session = function(self, session_data, directory)
            if not util.is_git_project() and not directory then
                directory = vim.fn.getcwd()
            end
            return original_api_create(self, session_data, directory)
        end
    end
end

-- Open opencode in a new tab with "current" position
-- Creates a new tab first, then toggles opencode to fill the tab
-- If current buffer is empty and unnamed, reuse it instead of creating a new tab
function M.toggle_in_new_tab()
    local opencode_api = require("opencode.api")
    local state = require("opencode.state")
    local config = require("opencode.config")

    -- If opencode is already open, just toggle it
    if state.windows and state.windows.output_win
        and vim.api.nvim_win_is_valid(state.windows.output_win) then
        opencode_api.toggle()
        return
    end

    -- Check if current buffer is empty and unnamed (fresh nvim instance)
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    local buf_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    local is_empty_unnamed = buf_name == "" and #buf_lines == 1 and buf_lines[1] == ""

    -- Only create new tab if current buffer is not empty/unnamed
    if not is_empty_unnamed then
        vim.cmd("tabnew")
    end

    -- Temporarily set position to "current" so opencode fills the tab
    local original_position = config.ui.position
    config.ui.position = "current"

    opencode_api.toggle()

    -- Restore original position for future toggles from within vim
    config.ui.position = original_position
end

-- Opencode keymap configuration
-- Note: <C-m> and <CR> are the same key code in terminals, so we use <C-s>
-- for insert mode submission instead.
M.keymap = {
    input_window = {
        ["<cr>"] = { "submit_input_prompt", mode = "n" },  -- Submit prompt (normal mode only)
        ["<C-s>"] = { "submit_input_prompt", mode = "i" }, -- Submit prompt (insert mode)
        ["<esc>"] = false,                                 -- Disable <esc> to close (use :q instead)
        ["~"] = { "mention_file", mode = "n" },            -- Pick a file and add to context
        ["@"] = { "mention", mode = "i" },                 -- Insert mention (file/agent)
        ["/"] = { "slash_commands", mode = "i" },          -- Pick a command to run
        ["#"] = { "context_items", mode = "i" },           -- Manage context items
    }
}

-- Opencode UI configuration
M.ui = {
    position = "right",
    output = {
        auto_scroll = true
    }
}

function M.opts()
    return {
        keymap = M.keymap,
        ui = M.ui
    }
end

function M.config()
    local res, opencode = pcall(require, "opencode")
    if not res then
        vim.notify("opencode not found", vim.log.levels.ERROR)
        return
    end

    opencode.setup(M.opts())

    -- Apply patch for non-git directory session handling
    M.patch_session_for_non_git()
end

return M
