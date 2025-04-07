-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

---@class options
local M = {}

M.meta = {
    desc = "Set global options",
    needs_setup = true,
}

-- Set global options
---@return nil
function M.set_options()
    -- Disable multiple space errors
    ---@diagnostic disable: codestyle-check
    local options = {
        autoindent = true,
        autoread = true,                  -- reload file if changed
        backup = false,                   -- creates a backup file
        cmdheight = 2,                    -- more space in the neovim command line
        colorcolumn = "80",               -- mark column at 80 chars
        completeopt = "menuone,noselect", -- mostly just for cmp
        conceallevel = 0,                 -- so that `` is visible in markdown files
        confirm = true,                   -- Bring up confirm pop up for unsaved buffers
        cursorline = true,                -- highlight the current line
        expandtab = true,                 -- convert tabs to spaces
        fileencoding = "utf-8",           -- the encoding written to a file
        foldmethod = "indent",
        foldlevel = 0,
        foldminlines = 3,      -- minimum number of lines in a fold
        foldnestmax = 5,       -- maximum depth of nested folds
        guicursor = "",        -- disable cursor style
        hlsearch = false,      -- search hl is taken care in autocmd
        inccommand = "split",  -- show split preview for replace
        ignorecase = true,     -- ignore case in search patterns
        laststatus = 3,        -- enable global status line
        list = true,           -- show some invisible characters
        mouse = "",            -- disable mouse
        number = true,         -- set numbered lines
        numberwidth = 4,       -- set number column width to 4 {default 4}
        pumheight = 10,        -- pop up menu height
        relativenumber = true, -- set relative numbered lines
        scrolloff = 5,         -- is one of my fav
        shell = "bash",        -- zsh has noglob issues with gtests in dap
        shiftround = true,     -- round indent to multiple of shiftwidth
        shiftwidth = 4,        -- the number of spaces inserted for each indentation
        showmode = false,      -- we don't need to see things like -- INSERT -- anymore
        showtabline = 4,       -- always show tabs
        sidescrolloff = 5,     -- add 5 lines padding while scrolling
        signcolumn = "yes",    -- always show the sign column, otherwise it would shift the text each time
        smartcase = true,      -- smart case
        smartindent = true,    -- make indenting smarter again
        softtabstop = 4,       -- tab is 4 spaces
        spell = true,          -- enable spell check
        splitbelow = true,     -- force all horizontal splits to go below current window
        splitright = true,     -- force all vertical splits to go to the right of current window
        swapfile = false,      -- creates a swapfile
        tabstop = 4,           -- insert 4 spaces for a tab
        termguicolors = true,  -- set term gui colors (most terminals support this)
        timeoutlen = 300,      -- time to wait for a mapped sequence to complete (in milliseconds)
        undodir = vim.fn.stdpath("data") .. "/undodir",
        undofile = true,
        undolevels = 10000,
        updatetime = 300,      -- faster completion (4000ms default)
        virtualedit = "block", -- allow cursor to move where there is no text
        wildchar = 4,          -- <C-d> for completion - https://neovim.io/doc/user/options.html#'wc'
        winborder = "rounded", -- rounded window border
        wrap = false,          -- display lines as one long line
        writebackup = false,   -- if a file is being edited by another program (or was written to file
        -- while editing with another program), it is not allowed to be edited
    }

    for k, v in pairs(options) do
        vim.api.nvim_set_option_value(k, v, {})
    end
end

-- Append global options
---@return nil
function M.append_options()
    -- Options to append (instead of set)
    local append_options = {
        diffopt = "algorithm:patience", -- Use patience diff algorithm
        iskeyword = "-", -- Match word-with-hypen for '*'
        listchars = "lead:⋅", -- Show leading spaces
        path = "**", -- Finding files - Search down into subfolders
        shortmess = "c", -- Show search preview in split
    }

    for k, v in pairs(append_options) do
        -- Retrieve current value
        local current_value = vim.api.nvim_get_option_value(k, {})

        -- Check if current value is a table
        if type(current_value) == table then
            table.insert(current_value, v)
        else
            -- Check if current value is comma-separated string
            if string.find(current_value, ",") then
                -- Append with a comma if already comma-separated
                current_value = current_value .. "," .. v
            else
                -- Append without a comma if not comma-separated
                current_value = current_value .. v
            end
        end
        vim.api.nvim_set_option_value(k, current_value, {})
    end
end

-- Enable build-in OSC52 clipboard provider
-- have to explicitly copy to '+' if needed in system clipboard
---@return nil
function M.set_clipboard()
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = require("vim.ui.clipboard.osc52").copy "+",
            ["*"] = require("vim.ui.clipboard.osc52").copy "*",
        },
        paste = {
            ["+"] = require("vim.ui.clipboard.osc52").paste "+",
            ["*"] = require("vim.ui.clipboard.osc52").paste "*",
        },
    }
end

-- Set misc options
---@return nil
function M.set_misc()
    -- Set shell to bash since zsh has noglob issues with gtests in dap
    vim.env.SHELL = "bash"

    -- User defined function to set list chars
    vim.g.u_list_chars_set = true

    -- Disable creating new file if doesn't exist
    vim.g.fsnonewfiles = 1

    -- Newtrw liststyle:
    -- https://medium.com/usevim/the-netrw-style-options-3ebe91d42456
    vim.g.netrw_liststyle = 3
end

-- User defined functions
---@return nil
function M.set_user_commands()
    -- User defined function to toggle list chars
    vim.api.nvim_create_user_command(
        'ToggleListChars',
        function()
            if vim.g.u_list_chars_set then
                vim.opt.listchars:remove "lead"
                vim.g.u_list_chars_set = false
            else
                vim.opt.listchars:append "lead:⋅"
                vim.g.u_list_chars_set = true
            end
        end, {}
    )

    -- User defined function to reload colorscheme
    -- Naming `ToggleColorScheme` is intentional since it's intended to call only
    -- when colorscheme is toggled by OS (dark/light)
    vim.api.nvim_create_user_command(
        'ToggleColorScheme',
        function()
            package.loaded["user.colorscheme"] = nil
            local colorscheme = require("user.colorscheme")
            if not colorscheme then
                vim.notify("Colorscheme not found", vim.log.levels.ERROR)
                return
            end

            -- Reload colorscheme silently
            vim.cmd("silent Lazy reload NeoSolarized.nvim")

            -- Reload bufferline silently
            vim.cmd("silent Lazy reload bufferline.nvim")

            -- Reload lualine silently
            vim.cmd("silent Lazy reload lualine.nvim")
        end, {}
    )
end

function M.setup()
    M.set_options()
    M.append_options()
    M.set_clipboard()
    M.set_misc()
    M.set_user_commands()
end

return M
