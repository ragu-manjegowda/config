-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Disable multiple space errors
---@diagnostic disable: codestyle-check
local options = {
    autoindent = true,
    backup = false,                          -- creates a backup file
    cmdheight = 2,                           -- more space in the neovim command line
    colorcolumn = "80",                      -- mark column at 80 chars
    completeopt = { "menuone", "noselect" }, -- mostly just for cmp
    conceallevel = 0,                        -- so that `` is visible in markdown files
    confirm = true,                          -- Bring up confirm pop up for unsaved buffers
    cursorline = true,                       -- highlight the current line
    expandtab = true,                        -- convert tabs to spaces
    fileencoding = "utf-8",                  -- the encoding written to a file
    guicursor = "",                          -- keep block cursor in insert mode
    hlsearch = false,                        -- search hl is taken care in autocmd
    inccommand = "split",                    -- show split preview for replace
    ignorecase = true,                       -- ignore case in search patterns
    laststatus = 3,                          -- enable global status line
    mouse = "",                              -- disable mouse
    number = true,                           -- set numbered lines
    numberwidth = 4,                         -- set number column width to 4 {default 4}
    pumheight = 10,                          -- pop up menu height
    relativenumber = true,                   -- set relative numbered lines
    scrolloff = 5,                           -- is one of my fav
    shiftround = true,                       -- round indent to multiple of shiftwidth
    shiftwidth = 4,                          -- the number of spaces inserted for each indentation
    showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
    showtabline = 4,                         -- always show tabs
    sidescrolloff = 5,                       -- add 5 lines padding while scrolling
    signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
    smartcase = true,                        -- smart case
    smartindent = true,                      -- make indenting smarter again
    softtabstop = 4,                         -- tab is 4 spaces
    spell = true,                            -- enable spell check
    splitbelow = true,                       -- force all horizontal splits to go below current window
    splitright = true,                       -- force all vertical splits to go to the right of current window
    swapfile = false,                        -- creates a swapfile
    syntax = "enable",
    tabstop = 4,                             -- insert 4 spaces for a tab
    termguicolors = true,                    -- set term gui colors (most terminals support this)
    timeoutlen = 1000,                       -- time to wait for a mapped sequence to complete (in milliseconds)
    undodir = vim.fn.expand("~/.cache/nvim/undodir"),
    undofile = true,
    undolevels = 10000,
    updatetime = 300,                        -- faster completion (4000ms default)
    wildchar = 4,                            -- <C-d> for completion - https://neovim.io/doc/user/options.html#'wc'
    wrap = false,                            -- display lines as one long line
    writebackup = false,                     -- if a file is being edited by another program (or was written to file
                                             -- while editing with another program), it is not allowed to be edited
}

vim.opt.diffopt:append { "algorithm:patience" } -- Use patience diff algorithm
vim.opt.iskeyword:append "-"                 -- Match word-with-hypen for '*'
vim.opt.list = true
vim.opt.listchars:append "lead:⋅"            -- Show leading spaces
vim.opt.path:append { '**' }                 -- Finding files - Search down into subfolders
vim.opt.shortmess:append "c"                 -- Show search preview in split

for k, v in pairs(options) do
    vim.opt[k] = v
end

-- Set shell to bash since zsh has noglob issues with gtests in dap
vim.env.SHELL = "bash"
vim.opt["shell"] = "bash"

------------------------------------------------------------------------------
-- Use system clipboard for yanks
------------------------------------------------------------------------------
if vim.fn.has('clipboard') == 1 then
  if vim.fn.has('unnamedplus') == 1 then
    vim.o.clipboard = 'unnamedplus'
  else
    vim.o.clipboard = 'unnamed'
  end
end
