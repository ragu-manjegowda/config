-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.opts()
    return {
        adapters = {
            openai = function()
                return require("codecompanion.adapters").extend("openai", {
                    url = "https://integrate.api.nvidia.com/v1/chat/completions",
                    env = {
                        api_key = os.getenv("OPENAI_API_KEY"),
                    },
                    schema = {
                        model = {
                            -- default = "nvdev/nvidia/llama-3.1-nemotron-70b-instruct"
                            default = "nvdev/qwen/qwen2.5-coder-32b-instruct"
                        },
                    },
                })
            end,
        },
        strategies = {
            -- Change the default chat adapter
            chat = { adapter = "openai", },
            inline = { adapter = "openai" },
            agent = { adapter = "openai" },
        }
    }
end

return M
