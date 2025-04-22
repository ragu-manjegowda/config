-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, image = pcall(require, "image")
    if not res then
        vim.notify("image not found", vim.log.levels.ERROR)
        return
    end

    image.setup({
        backend = "ueberzug",
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = true,
                download_remote_images = false,
                only_render_image_at_cursor = true,
                filetypes = { "markdown" },
            },
            neorg = {
                enabled = false,
            }
        }
    })
end

return M
