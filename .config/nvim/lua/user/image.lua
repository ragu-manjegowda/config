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

    -- Shorten function name
    local keymap = vim.keymap.set

    -- Open image under cursor in the Preview app (macOS)
    keymap("n", "<leader>io", function()
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
    end, {
        silent = true,
        desc = "xdg-open image under cursor"
    })
end

return M
