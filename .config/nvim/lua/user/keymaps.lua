-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

---@class keymaps
local M = {}

M.meta = {
    desc = "Set keymaps",
    needs_setup = true,
}

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

local utils

---@param mode string | table
---@param lhs string
---@param rhs string | function
---@param opts? table
---@return nil
function M.keymap(mode, lhs, rhs, opts)
    if not utils then
        utils = require("user.utils")
    end
    utils.keymap(mode, lhs, rhs, opts)
end

function M.setup()
    --Remap space as leader key
    M.keymap("", "<Space>", "<Nop>")
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -------------------------------------------------------------------------------
    -- Normal Mode
    -------------------------------------------------------------------------------

    -- Disable arrow keys in normal mode
    M.keymap("n", "<Up>", "<Nop>")
    M.keymap("n", "<Down>", "<Nop>")
    M.keymap("n", "<Left>", "<Nop>")
    M.keymap("n", "<Right>", "<Nop>")

    -- Disable q: since it comes in way most of the time, command history is
    -- mapped via telescope plugin
    M.keymap("n", "q:", "<Nop>")

    -- Scroll horizontally
    M.keymap("n", "<C-h>", "5zh")
    M.keymap("n", "<C-l>", "5zl")

    -- Resize with arrows
    M.keymap("n", "<C-Up>", ":resize -2<CR>")
    M.keymap("n", "<C-Down>", ":resize +2<CR>")
    M.keymap("n", "<C-Left>", ":vertical resize -2<CR>")
    M.keymap("n", "<C-Right>", ":vertical resize +2<CR>")

    -- Delete without yank
    M.keymap("n", "<leader>d", '"_d')
    M.keymap("n", "x", '"_x')
    M.keymap("n", "X", '"_X')
    M.keymap("v", "<leader>d", '"_d')

    -- Keep it centered
    M.keymap("n", "n", "nzzzv")
    M.keymap("n", "N", "Nzzzv")
    M.keymap("n", "J", "mzJ`z")

    -- ============ M.key maps for tabs
    -- Open new empty tab
    M.keymap("n", "<leader>n<Tab>", ":tabedit<CR>")

    -- Close all tabs except current
    M.keymap("n", "<leader>co", ":tabonly<CR>")

    -- Open terminal in new tab
    M.keymap("n", "<leader>zsh", ":tabnew term://zsh<CR>")
    M.keymap("n", "<leader>bash", ":tabnew term://bash -l<CR>")

    -- Write
    M.keymap("n", "<leader>w", ":w<CR>", { noremap = true })

    -- Quit
    M.keymap("n", "<leader>q", ":q<CR>")
    M.keymap("n", "<leader>qa", ":LspStop<CR>:qa<CR>")

    -- Map to open QuickFix list
    M.keymap("n", "<leader>oq", ":copen<CR><C-w>T")

    -- Map to navigate QuickFix list
    M.keymap("n", "<A-j>", "<cmd>cnext<CR>zz")
    M.keymap("n", "<A-k>", "<cmd>cprev<CR>zz")

    -- Map to navigate QuickFix list after error from Dispatch
    M.keymap("n", "<leader>od", ":Copen<CR><C-w>T")

    -- Get full path of the current buffer
    M.keymap("n", "<leader>fp", "1<C-g><CR>", { noremap = true })

    -------------------------------------------------------------------------------
    -- Insert Mode
    -------------------------------------------------------------------------------
    -- Forward delete characters
    M.keymap("i", "<C-d>", "<Del>")

    -------------------------------------------------------------------------------
    -- Visual Mode
    -------------------------------------------------------------------------------

    -- Stay in indent mode
    M.keymap("v", "<", "<gv")
    M.keymap("v", ">", ">gv")

    -- Paste without yank
    M.keymap("v", "p", '"_dP')

    -------------------------------------------------------------------------------
    -- Terminal Mode
    -------------------------------------------------------------------------------

    -- Terminal exit insert mode
    M.keymap("t", "jj", "<C-\\><C-n>")

    -------------------------------------------------------------------------------
    -- Copy to system clipboard
    -------------------------------------------------------------------------------
    -- Now the '+' register will copy to system clipboard using OSC52
    M.keymap({ 'n', 'v' }, '<leader>c', '"+y')
    M.keymap('n', '<leader>cc', '"+yy')

    -------------------------------------------------------------------------------
    -- URL handling
    -------------------------------------------------------------------------------

    -- source: https://sbulav.github.io/vim/neovim-opening-urls/
    if vim.fn.has("mac") == 1 then
        M.keymap("n", "gx", "<Cmd>call jobstart(['open', expand('<cfile>')], {'detach': v:true})<CR>")
    elseif vim.fn.has("unix") == 1 then
        M.keymap("n", "gx", "<Cmd>call jobstart(['xdg-open', expand('<cfile>')], {'detach': v:true})<CR>")
    else
        M.keymap("n", "gx", "<Cmd>lua print('Error: gx is not supported on this OS!')<CR>")
    end
end

return M
