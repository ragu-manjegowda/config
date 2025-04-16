-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, noice = pcall(require, "noice")
    if not res then
        vim.notify("noice not found", vim.log.levels.ERROR)
        return
    end

    local notify
    res, notify = pcall(require, "notify")
    if not res then
        vim.notify("notify not found", vim.log.ERROR)
        return
    else
        ---@diagnostic disable-next-line: undefined-field
        notify.setup({
            background_colour = "#000000"
        })
    end

    noice.setup({
        lsp = {
            hover = { enabled = false },
            signature = { enabled = false }
        },
        messages = {
            view_search = false,
        },
        notify = {
            replace = true
        },
        presets = {
            bottom_search = true,         -- use a classic bottom cmdline for search
            command_palette = true,       -- position the cmdline and popupmenu together
            long_message_to_split = true, -- long messages will be sent to a split
            inc_rename = false,           -- enables an input dialog for inc-rename.nvim
            lsp_doc_border = false,       -- add a border to hover docs and signature help
        },
        routes = {
            -- hide notification after writing to file
            {
                filter = {
                    event = "msg_show",
                    kind = "",
                    find = "written",
                },
                opts = { skip = true },
            }
        }
    })

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("Error loading user.utils", vim.log.levels.ERROR)
        return
    end

    local opts = function(desc)
        return {
            desc = "noice: " .. desc
        }
    end

    utils.keymap("n", "<leader>nd", "<cmd>Noice dismiss<CR>",
        opts("Noice dismiss"))

    utils.keymap("n", "<leader>nm", "<cmd>Noice<CR><C-W>T",
        opts("Noice messages"))

    -- show messages while recording macro
    -- https://github.com/folke/noice.nvim/issues/922#issuecomment-2254401041
    vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = function()
            local msg = string.format("Register:  %s", vim.fn.reg_recording())
            _MACRO_RECORDING_STATUS = true
            vim.notify(msg, vim.log.levels.INFO, {
                title = "Macro Recording",
                keep = function() return _MACRO_RECORDING_STATUS end,
            })
        end,
        group = vim.api.nvim_create_augroup(
            "NoiceMacroNotfication", { clear = true })
    })

    vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = function()
            _MACRO_RECORDING_STATUS = false
            vim.notify("Success!", vim.log.levels.INFO, {
                title = "Macro Recording End",
                timeout = 2000,
            })
        end,
        group = vim.api.nvim_create_augroup(
            "NoiceMacroNotficationDismiss", { clear = true })
    })

    -- Temporary workaround for https://github.com/folke/noice.nvim/issues/1082
    local initialWinborder = vim.o.winborder
    vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = function() vim.o.winborder = "none" end,
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        callback = function() vim.o.winborder = initialWinborder end,
    })
end

return M
