local options = {
    autoindent = true,
    backup = false,                          -- creates a backup file
    clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
    cmdheight = 2,                           -- more space in the neovim command line for displaying messages
    colorcolumn = "80",
    completeopt = { "menuone", "noselect" }, -- mostly just for cmp
    conceallevel = 0,                        -- so that `` is visible in markdown files
    cursorline = true,                       -- highlight the current line
    expandtab = true,                        -- convert tabs to spaces
    fileencoding = "utf-8",                  -- the encoding written to a file
    hlsearch = false,                        -- don't highlight all matches on previous search pattern
    ignorecase = true,                       -- ignore case in search patterns
    laststatus = 3,
    number = true,                           -- set numbered lines
    numberwidth = 4,                         -- set number column width to 4 {default 4}
    pumheight = 10,                          -- pop up menu height
    relativenumber = true,                   -- set relative numbered lines
    scrolloff = 5,                           -- is one of my fav
    shiftwidth = 4,                          -- the number of spaces inserted for each indentation
    showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
    showtabline = 4,                         -- always show tabs
    sidescrolloff = 5,
    signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
    smartcase = true,                        -- smart case
    smartindent = true,                      -- make indenting smarter again
    softtabstop = 4,
    splitbelow = true,                       -- force all horizontal splits to go below current window
    splitright = true,                       -- force all vertical splits to go to the right of current window
    swapfile = false,                        -- creates a swapfile
    syntax = enable,
    tabstop = 4,                             -- insert 4 spaces for a tab
    termguicolors = true,                    -- set term gui colors (most terminals support this)
    timeoutlen = 1000,                       -- time to wait for a mapped sequence to complete (in milliseconds)
    undodir = vim.fn.expand("~/.config/nvim/misc/undodir"),
    undofile = true,
    undolevels = 10000,
    updatetime = 300,                        -- faster completion (4000ms default)
    wrap = false,                            -- display lines as one long line
    writebackup = false,                     -- if a file is being edited by another program (or was written to file
                                             -- while editing with another program), it is not allowed to be edited
}

vim.opt.shortmess:append "c"

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
