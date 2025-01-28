-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.opts()
    return {
        -- add any opts here
        provider = "openai",
        openai = {
            endpoint = "https://integrate.api.nvidia.com/v1",
            -- model = "nvdev/nvidia/llama-3.1-nemotron-70b-instruct"
            model = "nvdev/meta/llama-3.1-405b-instruct"
        },
        azure = {}
    }
end

function M.img_clip_opts()
    return {
        -- recommended settings
        default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
                insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true
        }
    }
end

return M
