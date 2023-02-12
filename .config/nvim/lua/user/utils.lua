local vim = vim

local M = {}

local current_root_dir = vim.fn.getcwd()

function M.set_cwd()

    -- get git working directory
    local cwd = nil

    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

    -- if not git then active lsp client root
    if vim.v.shell_error ~= 0 then
        -- check if lsp is attached
        local lsp = vim.lsp.get_active_clients()
        if next(lsp) ~= nil then
            -- get the configured root directory of the first attached lsp.
            -- this gets messed up if we have multiple attached lsp's
            -- or even same lsp server with different root directories.
            cwd = lsp[1].config.root_dir
        end
    else
        cwd = git_root
    end

    if cwd ~= nil then
        if cwd ~= current_root_dir then
            --set root directory for vim
            vim.api.nvim_set_current_dir(cwd)
            current_root_dir = cwd
        end
    end
end

-- TODO: Return if mode is not visual
function M.getVisualSelection()
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

vim.api.nvim_create_autocmd(events, {
    pattern = "*",
    callback = function(_)
        -- update the current working directory
        M.set_cwd()
    end,
})

return M
