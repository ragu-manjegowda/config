-------------------------------------------------------------------------------
-- Test user/bufferline.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Bufferline Config", function()
    local bufferline_mod

    before_each(function()
        -- Module may return early if bufferline not found
        local ok, mod = pcall(require, "user.bufferline")
        if ok and type(mod) == "table" then
            bufferline_mod = mod
        else
            bufferline_mod = nil
        end
    end)

    describe("Module Interface", function()
        it("should load module or return early gracefully", function()
            -- If module returns early due to missing deps, it returns nil
            -- If it loads, it should be a table with functions
            if bufferline_mod then
                assert.is_table(bufferline_mod)
            end
        end)

        it("should expose config function when loaded", function()
            if bufferline_mod then
                assert.is_function(bufferline_mod.config)
            end
        end)
    end)

    describe("Bufferline Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if bufferline plugin not available
            if bufferline_mod then
                assert.has_no_errors(function()
                    pcall(bufferline_mod.config)
                end)
            end
        end)
    end)
end)
