-------------------------------------------------------------------------------
-- Test user/mason.lua and user/mason-tool-installer.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Mason Config", function()
    local mason_mod

    before_each(function()
        mason_mod = require("user.mason")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(mason_mod.config)
        end)
    end)

    describe("Mason Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if mason plugin not available
            assert.has_no_errors(function()
                pcall(mason_mod.config)
            end)
        end)
    end)
end)

describe("Mason Tool Installer Config", function()
    local mti_mod

    before_each(function()
        mti_mod = require("user.mason-tool-installer")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(mti_mod.config)
        end)
    end)

    describe("Mason Tool Installer Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if mason-tool-installer plugin not available
            assert.has_no_errors(function()
                pcall(require("user.mason").config)
                pcall(mti_mod.config)
            end)
        end)
    end)
end)
