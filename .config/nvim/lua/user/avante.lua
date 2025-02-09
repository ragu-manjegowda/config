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
            -- model = "nvdev/meta/llama-3.1-405b-instruct"
            model = "nvdev/qwen/qwen2.5-coder-32b-instruct",
            -- model = "nvdev/deepseek-ai/deepseek-r1",
            -- temperature = 0.6
            disable_tools = true
        },
        azure = {}
    }

    -- -- Disable folding for Avante filetypes
    -- vim.api.nvim_create_augroup("disable_folding", { clear = true })
    -- vim.api.nvim_create_autocmd("FileType", {
    --     pattern = { "Avante*" },
    --     group = "disable_folding",
    --     desc = "Disable folding for Avante filetypes",
    --     callback = function()
    --         vim.opt_local.foldenable = false
    --     end
    -- })
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
