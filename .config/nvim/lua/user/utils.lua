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
                vim.api.nvim_command("silent! LspStart")
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

-- Check if the current directory is a Bazel project
---@return boolean
function M.is_bazel_project()
    -- Check if either BUILD or WORKSPACE files exist in the project directory
    -- Define patterns for Bazel files (BUILD and WORKSPACE)
    local cwd = vim.fn.getcwd()
    local build_file_pattern = cwd .. '/BUILD'
    local workspace_file_pattern = cwd .. '/WORKSPACE'

    local has_build_file = vim.fn.filereadable(build_file_pattern) == 1
    local has_workspace_file = vim.fn.filereadable(workspace_file_pattern) == 1

    if has_build_file or has_workspace_file then
        return true
    else
        return false
    end
end

-- Reference
-- github.com/mfussenegger/nvim-dap/blob/6bf4de67dbe90271608e1c81797e5edc79ec6335/lua/dap/ui.lua#L42
function M.pick_one_sync(items, prompt, label_fn)
    local choices = { prompt }
    for i, item in ipairs(items) do
        table.insert(choices, string.format('%d: %s', i, label_fn(item)))
    end
    local choice = vim.fn.inputlist(choices)
    if choice < 1 or choice > #items then
        return nil
    end
    return items[choice]
end

function M.pick_one(items, prompt, label_fn, cb)
    local co
    if not cb then
        co = coroutine.running()
        if co then
            cb = function(item)
                coroutine.resume(co, item)
            end
        end
    end
    cb = vim.schedule_wrap(cb)
    if vim.ui then
        vim.ui.select(items, {
            prompt = prompt,
            format_item = label_fn,
        }, cb)
    else
        local result = M.pick_one_sync(items, prompt, label_fn)
        cb(result)
    end
    if co then
        return coroutine.yield()
    end
end

-- Utility functions to pick a file or directory using ui select
--
-- Reference:
-- github.com/mfussenegger/nvim-dap/blob/7bf34e0917d5daa6a397a9ba51f3d13d67cacb48/lua/dap/utils.lua#L278
--
-- Modified to fit needs

---@param opts {
---filter?: string|(fun(name: string):boolean),
---executables?: boolean, directories?: boolean}
---@return string[]
local function get_files(path, opts)
    local filter = function(_) return true end
    if opts.filter then
        if type(opts.filter) == "string" then
            filter = function(filepath)
                return filepath:find(opts.filter)
            end
        elseif type(opts.filter) == "function" then
            filter = function(filepath)
                return opts.filter(filepath)
            end
        else
            error('opts.filter must be a string or a function')
        end
    end

    local cmd
    if opts.directories then
        cmd = { "find", path, "-type", "d" }
    else
        cmd = { "find", path, "-type", "f" }
        if opts.executables then
            -- The order of options matters!
            table.insert(cmd, "-executable")
        end
    end
    table.insert(cmd, "-follow")

    local output = vim.fn.system(cmd)
    return vim.tbl_filter(filter, vim.split(output, '\n'))
end

---@param opts? {
---filter?: string|(fun(name: string): boolean),
---executables?: boolean, directories?: boolean,
---prompt?: string, path?: string }
---@return string|nil
function M.pick_file(opts)
    opts = opts or {}
    local executables = opts.executables == nil and true or opts.executables
    local directories = opts.directories == nil and true or opts.directories
    local prompt = opts.prompt or "Pick a file:"
    local path = opts.path or vim.fn.getcwd()
    local files = get_files(path, {
        filter = opts.filter,
        executables = executables,
        directories = directories
    })

    local co, ismain = coroutine.running()
    local pick = (co and not ismain) and M.pick_one or M.pick_one_sync

    if not vim.endswith(path, "/") then
        path = path .. "/"
    end

    ---@param abspath string
    ---@return string
    local function relpath(abspath)
        local _, end_ = abspath:find(path)
        return end_ and abspath:sub(end_ + 1) or abspath
    end
    return pick(files, prompt, relpath)
end

return M
