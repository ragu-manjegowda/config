local opts = { silent = true }

local term_opts = { silent = true }

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
keymap("n", "Up", "Nop", opts)
keymap("n", "Down", "Nop", opts)
keymap("n", "Left", "Nop", opts)
keymap("n", "Right", "Nop", opts)

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

-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)

-- ============ Key maps for tabs
-- Open new empty tab
keymap("n", "<leader>n<Tab>", ":tabedit<CR>", opts)

-- Close all tabs except current
keymap("n", "<leader>co", ":tabonly<CR>", opts)

-- Open terminal in new tab
keymap("n", "<leader>zsh", ":tabnew term://zsh<CR>", opts)
keymap("n", "<leader>bash", ":tabnew term://bash<CR>", opts)

-- Write
keymap("n", "<leader>w", ":w<CR>", { noremap = true })

-- Quit
keymap("n", "<leader>q", ":q<CR>", opts)
keymap("n", "<leader>qa", ":LspStop<CR>:qa<CR>", opts)

-- Map to navigate QuickFix list
keymap("n", "<leader>qo", ":copen<CR><C-w>T", opts)

-- Open toggle undo tree
keymap("n", "<leader>ut", ":UndotreeToggle<CR>", opts)

-- Get full path of the current buffer
keymap("n", "<leader>fp", "1<C-g><CR>", { noremap = true })

-- go substitute because the default map for sleeping is silly
keymap("n", "gs", ":%s/ / /gic<Left><Left><Left><Left><Left><Left><Left>", { noremap = true })


-------------------------------------------------------------------------------
-- Insert Mode
-------------------------------------------------------------------------------

-- Press jj fast to enter
keymap("i", "jj", "<ESC>", opts)
keymap("i", "<A-j>", "<ESC>:m .+1<CR>==i", opts)
keymap("i", "<A-k>", "<ESC>:m .-2<CR>==i", opts)

-------------------------------------------------------------------------------
-- Visual Mode
-------------------------------------------------------------------------------

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-------------------------------------------------------------------------------
-- Visual Block Mode
-------------------------------------------------------------------------------

-- Move text up and down
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)


-------------------------------------------------------------------------------
-- Terminal Mode
-------------------------------------------------------------------------------

-- Terminal exit insert mode
keymap("t", "<ESC><ESC>", "<C-\\><C-n>", opts)

