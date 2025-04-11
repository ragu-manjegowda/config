-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, neocodeium = pcall(require, "neocodeium")
    if not res then
        vim.notify("neocodeium not found", vim.log.levels.ERROR)
        return
    end

    neocodeium.setup({
        filetypes = {
            TelescopePrompt = false,
            ["dap-repl"] = false
        },
        -- server = {
        --     portal_url = "https://codeium-poc.hwinf-scm-aws.nvidia.com",
        --     api_url = "https://codeium-poc.hwinf-scm-aws.nvidia.com/_route/api_server",
        -- },
        silent = true
    })

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("Error loading user.utils", vim.log.levels.ERROR)
        return
    end

    local opts = function(desc)
        return {
            desc = "neocodeium: " .. desc
        }
    end

    utils.keymap('i', '<M-y>',
        neocodeium.accept_line,
        opts('Codeium suggestion accept line'))

    utils.keymap('i', '<M-f>',
        neocodeium.accept_word,
        opts('Codeium suggestion accept word'))

    utils.keymap('i', '<M-i>',
        neocodeium.cycle_or_complete,
        opts('Codeium suggestion next'))

    utils.keymap('i', '<M-o>',
        function()
            neocodeium.cycle_or_complete(-1)
        end,
        opts('Codeium suggestion prev'))

    utils.keymap('i', '<M-e>',
        neocodeium.clear,
        opts('Codeium suggestion clear'))
end

return M
