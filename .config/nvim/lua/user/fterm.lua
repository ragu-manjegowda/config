local vim = vim

local M = {}

local res, fterm = pcall(require, "FTerm")
if not res then
    vim.notify("FTerm not found", vim.log.levels.ERROR)
    return
end

local ftzsh = fterm:new({
    ft = 'fterm_zsh',
    cmd = "zsh",
    dimensions = {
        height = 0.9,
        width = 0.9
    }
})

-- Use this to toggle zsh in a floating terminal
function M.__fterm_zsh()
    ftzsh:toggle()
end

local function get_first_terminal()
    local terminal_chans = {}

    for _, chan in pairs(vim.api.nvim_list_chans()) do
        if chan["mode"] == "terminal" and chan["pty"] ~= "" then
            table.insert(terminal_chans, chan)
        end
    end

    table.sort(terminal_chans, function(left, right)
        return left["buffer"] < right["buffer"]
    end)

    if next(terminal_chans) == nil then
        return nil
    else
        return terminal_chans[1]["id"]
    end
end

function M.terminal_send(text)
    local first_terminal_chan = get_first_terminal()

    if first_terminal_chan == "" or first_terminal_chan == nil then
        vim.notify("[fterm] " .. "No open terminal available", vim.log.levels.WARN)
    else
        vim.api.nvim_chan_send(first_terminal_chan, text)
    end
end

function M.config()
    fterm.setup({
        border = 'double',
        dimensions  = {
            height = 0.9,
            width = 0.9,
        },
    })

    -- Keybindings
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    map('n', '<leader>ts', '<CMD>lua require("user.fterm").__fterm_zsh()<CR>', opts)
    map('t', '<leader>ts', '<C-\\><C-n><CMD>lua require("user.fterm").__fterm_zsh()<CR>', opts)
    map('n', '<leader>ss', '<CMD>lua require("user.fterm").terminal_send(vim.fn.input("> ") .. "\\n")<CR>', opts)
end

return M

