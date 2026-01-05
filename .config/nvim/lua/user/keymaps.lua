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

local desc = function(desc)
    return {
        desc = "user: " .. desc
    }
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

    -- Resize with arrows
    M.keymap("n", "<C-Up>", ":resize -2<CR>", desc("Resize up"))
    M.keymap("n", "<C-Down>", ":resize +2<CR>", desc("Resize down"))
    M.keymap("n", "<C-Left>", ":vertical resize -2<CR>", desc("Resize left"))
    M.keymap("n", "<C-Right>", ":vertical resize +2<CR>", desc("Resize right"))

    -- Delete without yank
    M.keymap("n", "<leader>d", '"_d', desc("Delete without yank"))
    M.keymap("n", "x", '"_x', desc("Delete without yank"))
    M.keymap("n", "X", '"_X', desc("Delete without yank"))
    M.keymap("v", "<leader>d", '"_d', desc("Delete without yank"))

    -- Keep it centered
    M.keymap("n", "n", "nzzzv")
    M.keymap("n", "N", "Nzzzv")
    M.keymap("n", "J", "mzJ`z")

    -- Yank command output
    M.keymap("n", "<leader>:", function()
        local cmd = vim.fn.input("Command: ")
        if cmd ~= "" then
            vim.cmd('redir @">')
            vim.cmd(cmd)
            vim.cmd("redir END")
            vim.notify('Command output copied to " register', vim.log.levels.INFO)
        end
    end, desc("Yank/copy command output"))

    M.keymap("n", "j", function()
        if vim.v.count > 0 then
            return "m'" .. vim.v.count .. "j"
        end
        return "j"
    end, { expr = true })

    M.keymap("n", "k", function()
        if vim.v.count > 0 then
            return "m'" .. vim.v.count .. "k"
        end
        return "k"
    end, { expr = true })

    -- ============ M.key maps for tabs
    -- Open new empty tab
    M.keymap("n", "<leader>n<Tab>", ":tabedit<CR>", desc("Open new empty tab"))

    -- Close all tabs except current
    M.keymap(
        "n", "<leader>co", ":tabonly<CR>",
        desc("Close all tabs except current"))

    -- Open terminal in new tab
    M.keymap("n", "<leader>zsh", ":tabnew term://zsh<CR>")
    M.keymap("n", "<leader>bash", ":tabnew term://bash -l<CR>")

    -- Write
    M.keymap("n", "<leader>w", ":w<CR>")

    -- Quit
    M.keymap("n", "<leader>q", ":q<CR>", desc("Quit"))
    M.keymap("n", "<leader>qa", function()
        if vim.fn.exists(":LspStop") == 2 then
            vim.cmd("LspStop")
        end
        vim.cmd("qa")
    end, desc("Quit all"))

    -- Map to open QuickFix list
    M.keymap("n", "<leader>oq", ":copen<CR><C-w>T", desc("Open QuickFix list"))

    -- Map to navigate QuickFix list
    M.keymap(
        "n", "<A-j>", "<cmd>cnext<CR>zz",
        desc("Open next item in QuickFix list"))
    M.keymap(
        "n", "<A-k>", "<cmd>cprev<CR>zz",
        desc("Open previous item in QuickFix list"))

    -- Map to navigate QuickFix list after error from Dispatch
    M.keymap(
        "n", "<leader>od", ":Copen<CR><C-w>T",
        desc("Open Dispatch error list"))

    -- Get full path of the current buffer
    M.keymap(
        "n", "<leader>fp", "1<C-g><CR>",
        desc("Get full path of the current buffer"))

    ---------------------------------------------------------------------------
    -- Insert Mode
    ---------------------------------------------------------------------------
    -- Forward delete characters
    M.keymap("i", "<C-d>", "<Del>", desc("Forward delete characters"))

    ---------------------------------------------------------------------------
    -- Visual Mode
    ---------------------------------------------------------------------------

    -- Stay in indent mode
    M.keymap("v", "<", "<gv")
    M.keymap("v", ">", ">gv")

    -- Paste without yank
    M.keymap("v", "p", '"_dP')

    ---------------------------------------------------------------------------
    -- Terminal Mode
    ---------------------------------------------------------------------------

    -- Terminal exit insert mode
    M.keymap("t", "jk", "<C-\\><C-n>", desc("Exit insert mode"))

    ---------------------------------------------------------------------------
    -- Copy to system clipboard
    ---------------------------------------------------------------------------
    -- Now the '+' register will copy to system clipboard using OSC52
    M.keymap(
        { "n", "v" }, "<leader>c", '"+y',
        desc("Copy to system clipboard"))
    M.keymap(
        "n", "<leader>cc", '"+yy', desc("Copy line to system clipboard"))

    ---------------------------------------------------------------------------
    -- Undo break, give better undo experience
    ---------------------------------------------------------------------------
    M.keymap("i", "<Space>", "<Space><C-g>u")
    M.keymap("i", "<Tab>", "<Tab><C-g>u")
    M.keymap("i", "<CR>", "<CR><C-g>u")
    M.keymap("i", ",", ",<C-g>u")
    M.keymap("i", ".", ".<C-g>u")
    M.keymap("i", "!", "!<C-g>u")
    M.keymap("i", "?", "?<C-g>u")
    M.keymap("i", "(", "(<C-g>u")
    M.keymap("i", ")", ")<C-g>u")
    M.keymap("i", '"', '"<C-g>u')
    M.keymap("i", "[", "[<C-g>u")
    M.keymap("i", "]", "]<C-g>u")
    M.keymap("i", ";", ";<C-g>u")

    ---------------------------------------------------------------------------
    -- URL handling
    ---------------------------------------------------------------------------

    -- source: https://sbulav.github.io/vim/neovim-opening-urls/
    if vim.fn.has("mac") == 1 then
        M.keymap(
            "n", "gx",
            "<Cmd>call jobstart(['open', expand('<cfile>')], {'detach': v:true})<CR>",
            desc("Open URL under cursor"))
    elseif vim.fn.has("unix") == 1 then
        M.keymap(
            "n", "gx",
            "<Cmd>call jobstart(['xdg-open', expand('<cfile>')], {'detach': v:true})<CR>",
            desc("Open URL under cursor"))
    else
        M.keymap(
            "n", "gx",
            "<Cmd>lua print('Error: gx is not supported on this OS!')<CR>",
            desc("Open URL under cursor"))
    end

    -- Open image under cursor in the default image viewer
    M.keymap("n", "<leader>io", function()
        local function get_image_path()
            -- Get the current line
            local line = vim.api.nvim_get_current_line()
            -- Pattern to match image path in Markdown
            local image_pattern = "%[.-%]%((.-)%)"
            -- Extract relative image path
            local _, _, image_path = string.find(line, image_pattern)

            return image_path
        end

        -- Get the image path
        local image_path = get_image_path()

        if image_path then
            -- Check if the image path starts with "http" or "https"
            if string.sub(image_path, 1, 4) == "http" then
                print("URL image, use 'gx' to open it in the default browser.")
            else
                -- Construct absolute image path
                local current_file_path = vim.fn.expand("%:p:h")
                local absolute_image_path = current_file_path .. "/" .. image_path

                -- Construct command to open image in Preview
                local command

                ---@diagnostic disable-next-line: undefined-field
                if not vim.loop.os_uname().sysname == "Darwin" then
                    command = "open "
                else
                    command = "xdg-open "
                end

                -- Append the absolute image path
                command = command .. vim.fn.shellescape(absolute_image_path)

                -- Execute the command
                local success = os.execute(command)

                if success then
                    print("Opened image: " .. absolute_image_path)
                else
                    print("Failed to open image: " .. absolute_image_path)
                end
            end
        else
            print("No image found under the cursor")
        end
    end, desc("Open image under cursor"))
end

return M
