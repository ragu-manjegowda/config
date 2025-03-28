-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

M.config = function()
    local res, lualine = pcall(require, "lualine")
    if not res then
        vim.notify("lualine not found", vim.log.levels.ERROR)
        return
    end

    local function getSearch(opts)
        -- Check if noice plugin is loaded
        local noice_exists, noice = pcall(require, "noice")

        if noice_exists then
            if opts.cond then
                return noice.api.status.search.has
            end

            if opts.count then
                return noice.api.status.search.get
            end
        end
        return nil
    end

    lualine.setup {
        options = {
            theme = "solarized_light",
            disabled_filetypes = {
                statusline = {
                    "NvimTree"
                }
            },
            ignore_focus = {
                "NvimTree"
            },
            always_divide_middle = true,
            globalstatus = false,
        },
        sections = {
            lualine_x = {
                {
                    getSearch({ count = true }),
                    cond = getSearch({ cond = true }),
                },
                'lsp_status', 'encoding',
                'fileformat', 'filetype' }
        },
        inactive_sections = {
            lualine_b = { 'diff' },
            lualine_x = { 'progress' },
            lualine_y = { 'location' },
        },
        extensions = {}
    }

    vim.api.nvim_set_hl(0, "StatusLine", { reverse = false })
    vim.api.nvim_set_hl(0, "StatusLineNC", { reverse = false })
end

return M
