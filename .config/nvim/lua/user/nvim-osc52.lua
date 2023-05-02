-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, nvim_osc52 = pcall(require, "osc52")
    if not res then
        vim.notify("nvim-osc52 not found", vim.log.levels.WARN)
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
        return
    end

    local function copy(lines, _)
        nvim_osc52.copy(table.concat(lines, '\n'))
    end

    local function paste()
        return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
    end

    vim.g.clipboard = {
        name = 'osc52',
        copy = { ['+'] = copy,['*'] = copy },
        paste = { ['+'] = paste,['*'] = paste },
    }

    -- Now the '+' register will copy to system clipboard using OSC52
    vim.keymap.set({ 'n', 'v' }, '<leader>c', '"+y')
    vim.keymap.set('n', '<leader>cc', '"+yy')
end

return M

