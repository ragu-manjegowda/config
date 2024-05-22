-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

local current_root_dir = nil

local function restore_nvim_tree()
    local res, nvim_tree_api, nvim_tree_change_dir

    res, nvim_tree_api = pcall(require, "nvim-tree.api")
    if not res then
        vim.notify("nvim-tree.api not found", vim.log.levels.ERROR)
        return
    end

    res, nvim_tree_change_dir = pcall(require,
        "nvim-tree.actions.root.change-dir")

    if not res then
        vim.notify("nvim-tree.actions.root.current-dir not found",
            vim.log.levels.ERROR)

        return
    end

    if current_root_dir ~= nil then
        nvim_tree_change_dir.fn(current_root_dir)
        return
    end

    nvim_tree_api.tree.reload()
end

local function set_session_directory()
    if current_root_dir == nil or current_root_dir == '/' then
        return
    end

    local path = current_root_dir
    path = vim.fn.substitute(path, '\\v\\/', '_', 'g')
    path = vim.fn.substitute(path, '_', '', '')
    path = vim.fn.substitute(path, '\\v\\.', '', 'g')
    path = vim.fn.substitute(path, '[A-Z]', '\\U&', 'g')

    vim.g.session_autosave_to = path
end

function M.set_cwd()
    -- get git working directory
    local cwd = nil

    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

    -- if not git then active lsp client root
    if vim.v.shell_error ~= 0 then
        -- check if lsp is attached
        local lsp = vim.lsp.get_clients()
        if next(lsp) ~= nil then
            -- get the configured root directory of the first attached lsp.
            -- this gets messed up if we have multiple attached lsp's
            -- or even same lsp server with different root directories.
            cwd = lsp[1].config.root_dir
        end
    else
        cwd = git_root
    end

    if cwd == nil and current_root_dir == nil then
        cwd = vim.fn.getcwd()
    end

    if cwd ~= nil then
        if cwd ~= current_root_dir then
            --set root directory for vim
            vim.api.nvim_set_current_dir(cwd)
            current_root_dir = cwd
            -- restore nvim tree
            restore_nvim_tree()
            -- update session directory
            set_session_directory()
        end
    else
        current_root_dir = vim.fn.getcwd()
        -- restore nvim tree
        restore_nvim_tree()
    end
end

function M.getVisualSelection()
    -- If not in visual mode, return empty string
    if vim.api.nvim_get_mode()["mode"] ~= 'v' then
        return ''
    end

    vim.cmd('noau normal! "vy"')
    local text = vim.fn.getreg('v')
    vim.fn.setreg('v', {})

    text = string.gsub(text, "\n", "")
    if #text > 0 then
        return text
    else
        return ''
    end
end

-- Updating the current working directory
local events = { 'LspAttach', 'VimEnter' }

-- Lsp is started after filetype, however, Lazy plugin manager doesn't seem to
-- have relevant event to trigger loading lspconfig hence this hack to
-- explicitly call `LspStart` via autocmd
local vim_enter_lsp_status = nil

vim.api.nvim_create_autocmd(events, {
    pattern = "*",
    callback = function(_)
        -- update the current working directory
        M.set_cwd()
        -- Do it just once, if vim is started with argument
        if vim_enter_lsp_status == nil then
            -- Get list of attached clients
            local lsp = vim.lsp.get_clients()
            -- If there is no client attached, call `LspStart`
            if next(lsp) == nil then
                vim.cmd("LspStart")
                vim_enter_lsp_status = true
            end
        end
    end,
})

vim.api.nvim_create_autocmd('DirChanged', {
    pattern = "auto", -- trigger on autochdir
    callback = function(_)
        current_root_dir = vim.fn.getcwd()
        -- set session directory
        set_session_directory()
    end,
})

return M
