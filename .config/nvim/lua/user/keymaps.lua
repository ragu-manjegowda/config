-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local opts = { silent = true }

-- Shorten function name
local keymap = vim.keymap.set

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-------------------------------------------------------------------------------
-- Normal Mode
-------------------------------------------------------------------------------

-- Disable arrow keys in normal mode
keymap("n", "<Up>", "<Nop>", opts)
keymap("n", "<Down>", "<Nop>", opts)
keymap("n", "<Left>", "<Nop>", opts)
keymap("n", "<Right>", "<Nop>", opts)

-- Disable q: since it comes in way most of the time, command history is
-- mapped via telescope plugin
keymap("n", "q:", "<Nop>", opts)

-- Scroll horizontally
keymap("n", "<C-h>", "5zh", opts)
keymap("n", "<C-l>", "5zl", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Delete without yank
keymap("n", "<leader>d", '"_d', opts)
keymap("n", "x", '"_x', opts)
keymap("n", "X", '"_X', opts)
keymap("v", "<leader>d", '"_d', opts)

-- Keep it centered
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)
keymap("n", "J", "mzJ`z", opts)

-- ============ Key maps for tabs
-- Open new empty tab
keymap("n", "<leader>n<Tab>", ":tabedit<CR>", opts)

-- Close all tabs except current
keymap("n", "<leader>co", ":tabonly<CR>", opts)

-- Open terminal in new tab
keymap("n", "<leader>zsh", ":tabnew term://zsh<CR>", opts)
keymap("n", "<leader>bash", ":tabnew term://bash -l<CR>", opts)

-- Write
keymap("n", "<leader>w", ":w<CR>", { noremap = true })

-- Quit
keymap("n", "<leader>q", ":q<CR>", opts)
keymap("n", "<leader>qa", ":LspStop<CR>:qa<CR>", opts)

-- Map to open QuickFix list
keymap("n", "<leader>oq", ":copen<CR><C-w>T", opts)

-- Map to navigate QuickFix list
keymap("n", "<A-j>", "<cmd>cnext<CR>zz", opts)
keymap("n", "<A-k>", "<cmd>cprev<CR>zz", opts)

-- Map to navigate QuickFix list after error from Dispatch
keymap("n", "<leader>od", ":Copen<CR><C-w>T", opts)

-- Get full path of the current buffer
keymap("n", "<leader>fp", "1<C-g><CR>", { noremap = true })

-------------------------------------------------------------------------------
-- Insert Mode
-------------------------------------------------------------------------------
-- Forward delete characters
keymap("i", "<C-d>", "<Del>", opts)

-------------------------------------------------------------------------------
-- Visual Mode
-------------------------------------------------------------------------------

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Paste without yank
keymap("v", "p", '"_dP', opts)

-------------------------------------------------------------------------------
-- Terminal Mode
-------------------------------------------------------------------------------

-- Terminal exit insert mode
keymap("t", "jj", "<C-\\><C-n>", opts)

-------------------------------------------------------------------------------
-- Copy to system clipboard
-------------------------------------------------------------------------------
-- Now the '+' register will copy to system clipboard using OSC52
keymap({ 'n', 'v' }, '<leader>c', '"+y', opts)
keymap('n', '<leader>cc', '"+yy', opts)

-------------------------------------------------------------------------------
-- URL handling
-------------------------------------------------------------------------------

-- source: https://sbulav.github.io/vim/neovim-opening-urls/
if vim.fn.has("mac") == 1 then
    keymap("n", "gx", "<Cmd>call jobstart(['open', expand('<cfile>')], {'detach': v:true})<CR>", opts)
elseif vim.fn.has("unix") == 1 then
    keymap("n", "gx", "<Cmd>call jobstart(['xdg-open', expand('<cfile>')], {'detach': v:true})<CR>", opts)
else
    keymap("n", "gx", "<Cmd>lua print('Error: gx is not supported on this OS!')<CR>", opts)
end
