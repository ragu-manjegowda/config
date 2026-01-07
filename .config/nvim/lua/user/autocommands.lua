-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

---@class autocommands
local M = {}

M.meta = {
    desc = "Set autocommands",
    needs_setup = true,
}

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

-- Set autocommands using vimscript
---@return nil
function M.set_autocommands_using_vimscript()
    vim.cmd [[

        " Delete all other lines except ones containing args
        function! GrepQuickFix(pat)
            let all = getqflist()
            for d in all
                if bufname(d['bufnr']) !~ a:pat && d['text'] !~ a:pat
                    call remove(all, index(all,d))
                endif
            endfor
            call setqflist(all)
        endfunction

        command! -nargs=* QFGrep call GrepQuickFix(<q-args>)

        " Delete all other lines except ones containing args
        function! RemoveQuickFix(pat)
            let all = getqflist()
            for d in all
                if bufname(d['bufnr']) =~ a:pat || d['text'] =~ a:pat
                    call remove(all, index(all,d))
                endif
            endfor
            call setqflist(all)
        endfunction

        command! -nargs=* QFRemove call RemoveQuickFix(<q-args>)

        " Sort quick fix list
        function! s:CompareQuickfixEntries(i1, i2)
            if bufname(a:i1.bufnr) == bufname(a:i2.bufnr)
                return a:i1.lnum == a:i2.lnum ? 0 : (a:i1.lnum < a:i2.lnum ? -1 : 1)
            else
                return bufname(a:i1.bufnr) < bufname(a:i2.bufnr) ? -1 : 1
            endif
        endfunction

        function! s:SortUniqQFList()
            let sortedList = sort(getqflist(), 's:CompareQuickfixEntries')
            let uniqedList = []
            let last = ''
            for item in sortedList
                let this = bufname(item.bufnr) . "\t" . item.lnum
                if this !=# last
                    call add(uniqedList, item)
                    let last = this
                    endif
            endfor
            call setqflist(uniqedList)
        endfunction

        command! QFSort call s:SortUniqQFList()

    ]]
end

-- Set autocommands using lua
---@return nil
function M.set_autocommands_using_lua()
    local function toggle_zoom()
        local zoomed = vim.b.zoomed
        if zoomed and zoomed == 1 then
            vim.cmd(vim.b.zoom_winrestcmd)
            vim.b.zoomed = 0
        else
            vim.b.zoom_winrestcmd = vim.fn.winrestcmd()
            vim.cmd("resize")
            vim.cmd("vertical resize")
            vim.b.zoomed = 1
        end
    end

    M.keymap("n", "<leader>z", toggle_zoom, { desc = "Toggle zoom" })

    -- Utility function to switch between header and source files in cpp
    local function setup_fswitch()
        vim.api.nvim_create_augroup("fswitch_h", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                vim.b.fswitchdst = "c,_interface.cpp,cpp"
                vim.b.fswitchlocs = "reg:|include.*|src/**|"
                vim.b.fswitchfnames = "/$/_interface/"
            end,
            desc = "Switch between source files for .h header files",
            group = "fswitch_h",
            pattern = "*.h"
        })

        vim.api.nvim_create_augroup("fswitch_hpp", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                vim.b.fswitchdst = "cpp"
                vim.b.fswitchlocs = "reg:|include.*|src/**|,./impl"
            end,
            desc = "Switch between source files for .hpp header files",
            group = "fswitch_hpp",
            pattern = "*.hpp"
        })

        vim.api.nvim_create_augroup("fswitch_cpp", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                vim.b.fswitchdst = "hpp"
                vim.b.fswitchlocs = "reg:|include.*|src/**|,../"
            end,
            desc = "Switch between header files for .cpp source files",
            group = "fswitch_cpp",
            pattern = "*.cpp"
        })

        vim.api.nvim_create_augroup("fswitch_interface_cpp", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                vim.b.fswitchdst = "h"
                vim.b.fswitchfnames = "/_interface$//"
            end,
            desc = "Switch between header files for _interface.cpp source files",
            group = "fswitch_interface_cpp",
            pattern = "*_interface.cpp"
        })

        M.keymap(
            "n", "<leader>oh", ":FSTab<CR>",
            {
                desc = "Switch between header and source files"
            }
        )
    end

    setup_fswitch()


    -- add keymap for QuickFix list
    vim.api.nvim_create_augroup("qf_keymaps", { clear = true })
    vim.api.nvim_create_autocmd(
        { "FileType" },
        {
            callback = function()
                M.keymap(
                    "n", "<leader>v", "<C-w><CR><C-w>L",
                    {
                        buffer = true,
                        desc = "Open in vertical split"
                    }
                )

                M.keymap(
                    "n", "<leader><Tab>", "<C-w><CR><C-w>T",
                    {
                        buffer = true,
                        desc = "Open in new tab"
                    }
                )
            end,
            desc     = "Add keymap for QuickFix list",
            group    = "qf_keymaps",
            pattern  = { "qf" }
        }
    )

    -- remove trailing whitespaces
    vim.api.nvim_create_augroup("remove_trailing_whitespaces", { clear = true })
    vim.api.nvim_create_autocmd(
        { "BufWritePre" },
        {
            callback = function()
                local ft = vim.bo.filetype
                if ft == "mail" or ft == "markdown" or ft == "rmd" or ft == "text"
                    or ft == "rst" then
                    return
                end
                -- Save current cursor position
                local save_cursor = vim.fn.getcurpos()
                vim.cmd(":%s/\\s\\+$//e")
                -- Set cursor position to the saved position
                vim.fn.setpos(".", save_cursor)
            end,
            desc     = "Remove trailing whitespaces",
            group    = "remove_trailing_whitespaces",
            pattern  = "*"
        }
    )

    -- highlight yanks
    vim.api.nvim_create_augroup("highlight_yanks", { clear = true })
    vim.api.nvim_create_autocmd(
        { "TextYankPost" },
        {
            callback = function()
                vim.highlight.on_yank { timeout = 500 }
            end,
            desc     = "Highlight yanks",
            group    = "highlight_yanks",
            pattern  = "*"
        }
    )

    -- pager mappings for Manual
    vim.api.nvim_create_augroup("manpage_keymaps", { clear = true })
    vim.api.nvim_create_autocmd(
        { "FileType" },
        {
            callback = function()
                M.keymap(
                    "n", "<enter>", "K",
                    {
                        buffer = true,
                        desc = "Go to section"
                    }
                )
                M.keymap(
                    "n", "<backspace>", "<c-o>",
                    {
                        buffer = true,
                        desc = "Go back"
                    }
                )
            end,
            desc     = "Add pager mappings for Manual",
            group    = "manpage_keymaps",
            pattern  = { "man", "help" }
        }
    )

    -- Mason update
    vim.api.nvim_create_augroup("mason_update", { clear = true })
    vim.api.nvim_create_autocmd("User",
        {
            callback = function()
                vim.schedule(function()
                    vim.notify(
                        "Mason-tool-installer has finished",
                        vim.log.levels.INFO)
                end)
            end,
            desc = "Mason update",
            group = "mason_update",
            pattern = "MasonToolsUpdateCompleted"
        }
    )

    -- Set match pairs for c, cpp
    -- Remove `-` from iskeyword to avoid not matching pointer variables
    -- Ex: `this->pointer` considers `this-` but not `this` when matching words
    vim.api.nvim_create_augroup("match_pairs", { clear = true })
    vim.api.nvim_create_autocmd("FileType",
        {
            callback = function()
                vim.opt.mps:append "=:;"
                ---@diagnostic disable-next-line: undefined-field
                vim.opt.iskeyword:remove "-"
            end,
            desc = "Set match pairs for c, cpp",
            group = "match_pairs",
            pattern = { "cpp", "c" }
        }
    )

    -- Fix gf functionality inside .lua files
    vim.api.nvim_create_augroup("lua_gf", { clear = true })
    vim.api.nvim_create_autocmd("FileType",
        {
            callback = function()
                ---@diagnostic disable: assign-type-mismatch
                -- credit: https://github.com/sam4llis/nvim-lua-gf
                vim.opt_local.include = [[\v<((do|load)file|require|reload)[^''"]*[''"]\zs[^''"]+]]
                vim.opt_local.includeexpr = "substitute(v:fname,'\\.','/','g')"
                vim.opt_local.suffixesadd:prepend ".lua"
                vim.opt_local.suffixesadd:prepend "init.lua"

                for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
                    vim.opt_local.path:append(path .. "/lua")
                end
            end,
            desc = "Fix gf functionality inside .lua files",
            group = "lua_gf",
            pattern = { "lua" }
        }
    )

    -- Resize window when vim is resized
    -- credit: https://github.com/LunarVim/LunarVim
    vim.api.nvim_create_augroup("resize_window", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", {
        command = "tabdo wincmd =",
        desc = "Resize window when vim is resized",
        group = "resize_window",
        pattern = "*"
    })

    -- Disable displaying leading spaces for certain filetypes
    vim.api.nvim_create_augroup("disable_leading_spaces", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        callback = function()
            vim.opt.list = false
            vim.opt.listchars:remove "lead"
            vim.opt_local.textwidth = 72
        end,
        desc = "Disable leading spaces for certain filetypes",
        group = "disable_leading_spaces",
        pattern = { "checkhealth", "fugitive", "gitcommit", "text" }
    })

    -- Stop lsp client when no buffer is attached
    -- credit: https://www.reddit.com/r/neovim/s/1Xe19oPOVX
    vim.api.nvim_create_augroup("stop_lsp_with_last_client", { clear = true })
    vim.api.nvim_create_autocmd({ "LspDetach" }, {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or not client.attached_buffers then return end
            for buf_id in pairs(client.attached_buffers) do
                if buf_id ~= args.buf then return end
            end
            client:stop()
        end,
        group = "stop_lsp_with_last_client",
        desc = "Stop lsp client when no buffer is attached",
    })
end

function M.setup()
    M.set_autocommands_using_vimscript()
    M.set_autocommands_using_lua()
end

return M
