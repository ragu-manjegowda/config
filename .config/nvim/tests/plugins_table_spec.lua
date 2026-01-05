-------------------------------------------------------------------------------
-- Test plugin table structure and config module validity
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications when loading modules that have missing dependencies
vim.notify = function(_, _, _) end

describe("Plugin Table Validation", function()
    -- List of all user config modules that should be loadable
    local config_modules = {
        "user.bazel",
        "user.blink-cmp",
        "user.bracketed",
        "user.bufferline",
        "user.colorscheme",
        "user.dap",
        "user.dapui",
        "user.diffview",
        "user.files",
        "user.flatten",
        "user.fterm",
        "user.fugitive",
        "user.gitsigns",
        "user.indent-blankline",
        "user.lspconfig",
        "user.lspsaga",
        "user.lualine",
        "user.markview",
        "user.mason",
        "user.mason-tool-installer",
        "user.neocodeium",
        "user.neovim-session-manager",
        "user.noice",
        "user.nvim-select-multi-line",
        "user.nvim-tree",
        "user.rainbow-delimiters",
        "user.remote-nvim",
        "user.smoothcursor",
        "user.telescope",
        "user.treesitter",
        "user.utils",
        "user.which-key",
    }

    describe("Config Modules", function()
        it("all config modules should be loadable without errors", function()
            for _, mod_name in ipairs(config_modules) do
                local ok, err = pcall(require, mod_name)
                assert.is_true(ok, "Failed to load " .. mod_name .. ": " .. tostring(err))
            end
        end)
    end)

    describe("Plugin Specs Structure", function()
        local plugins

        before_each(function()
            -- Load with default (all_plugins)
            vim.g.blazing_fast = nil
            package.loaded["user.plugins-table"] = nil
            plugins = require("user.plugins-table")
        end)

        it("should return a table of plugins", function()
            assert.is_table(plugins)
            assert.is_true(#plugins > 0, "Plugin table should not be empty")
        end)

        it("each plugin should have a valid repo string as first element", function()
            for i, plugin in ipairs(plugins) do
                assert.is_truthy(plugin[1],
                    "Plugin #" .. i .. " missing repo string")
                assert.is_string(plugin[1],
                    "Plugin #" .. i .. " first element should be string")
                -- Should match pattern "owner/repo"
                assert.is_truthy(string.match(plugin[1], "^[%w%-_%.]+/[%w%-_%.]+$"),
                    "Plugin #" .. i .. " (" .. plugin[1] .. ") should match owner/repo pattern")
            end
        end)

        it("config field should be a function when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.config ~= nil then
                    assert.is_function(plugin.config,
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") config must be function")
                end
            end
        end)

        it("opts field should be table or function when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.opts ~= nil then
                    local opts_type = type(plugin.opts)
                    assert.is_truthy(
                        opts_type == "table" or opts_type == "function",
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") opts must be table or function, got " .. opts_type
                    )
                end
            end
        end)

        it("init field should be a function when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.init ~= nil then
                    assert.is_function(plugin.init,
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") init must be function")
                end
            end
        end)

        it("dependencies field should be table when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.dependencies ~= nil then
                    assert.is_table(plugin.dependencies,
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") dependencies must be table")
                end
            end
        end)

        it("event field should be string or table when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.event ~= nil then
                    local event_type = type(plugin.event)
                    assert.is_truthy(
                        event_type == "string" or event_type == "table",
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") event must be string or table"
                    )
                end
            end
        end)

        it("lazy field should be boolean when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.lazy ~= nil then
                    assert.is_boolean(plugin.lazy,
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") lazy must be boolean")
                end
            end
        end)

        it("priority field should be number when present", function()
            for i, plugin in ipairs(plugins) do
                if plugin.priority ~= nil then
                    assert.is_number(plugin.priority,
                        "Plugin #" .. i .. " (" .. plugin[1] .. ") priority must be number")
                end
            end
        end)
    end)

    describe("Blazing Fast Modes", function()
        it("blazing_fast=1 should return extra_plugins subset", function()
            vim.g.blazing_fast = 1
            package.loaded["user.plugins-table"] = nil
            local extra = require("user.plugins-table")

            assert.is_table(extra)
            assert.is_true(#extra > 0)

            -- extra_plugins should include core plugins
            local has_lazy = false
            for _, p in ipairs(extra) do
                if p[1] == "folke/lazy.nvim" then has_lazy = true end
            end
            assert.is_true(has_lazy, "extra_plugins should include lazy.nvim")
        end)

        it("blazing_fast=2 should return core_plugins subset", function()
            vim.g.blazing_fast = 2
            package.loaded["user.plugins-table"] = nil
            local core = require("user.plugins-table")

            assert.is_table(core)
            assert.is_true(#core > 0)

            -- core_plugins should have lazy.nvim
            local has_lazy = false
            for _, p in ipairs(core) do
                if p[1] == "folke/lazy.nvim" then has_lazy = true end
            end
            assert.is_true(has_lazy, "core_plugins should include lazy.nvim")
        end)

        it("blazing_fast=2 should set performance options", function()
            vim.g.blazing_fast = 2
            package.loaded["user.plugins-table"] = nil
            require("user.plugins-table")

            assert.equals("manual", vim.opt.foldmethod:get())
            assert.is_false(vim.opt.list:get())
            assert.is_false(vim.opt.swapfile:get())
        end)

        after_each(function()
            vim.g.blazing_fast = nil
            package.loaded["user.plugins-table"] = nil
        end)
    end)

    describe("Config Module Contracts", function()
        -- Modules that should have a config() function
        local config_function_modules = {
            "user.bufferline",
            "user.colorscheme",
            "user.dap",
            "user.dapui",
            "user.diffview",
            "user.files",
            "user.fterm",
            "user.fugitive",
            "user.gitsigns",
            "user.indent-blankline",
            "user.lspconfig",
            "user.lspsaga",
            "user.lualine",
            "user.markview",
            "user.mason",
            "user.mason-tool-installer",
            "user.neocodeium",
            "user.neovim-session-manager",
            "user.noice",
            "user.nvim-tree",
            "user.rainbow-delimiters",
            "user.remote-nvim",
            "user.smoothcursor",
            "user.telescope",
            "user.treesitter",
            "user.which-key",
        }

        -- Modules that should have an opts() function
        local opts_function_modules = {
            "user.blink-cmp",
            "user.flatten",
        }

        -- Modules that should have a before() function
        local before_function_modules = {
            "user.bazel",
            "user.nvim-select-multi-line",
            "user.telescope",
            "user.which-key",
        }

        it("config() function modules should expose config function", function()
            for _, mod_name in ipairs(config_function_modules) do
                local ok, mod = pcall(require, mod_name)
                assert.is_true(ok, "Failed to load " .. mod_name)
                -- Some modules return early if deps not found, skip those
                if type(mod) == "table" then
                    assert.is_function(mod.config,
                        mod_name .. " should have config() function")
                end
            end
        end)

        it("opts() function modules should expose opts function", function()
            for _, mod_name in ipairs(opts_function_modules) do
                local ok, mod = pcall(require, mod_name)
                assert.is_true(ok, "Failed to load " .. mod_name)
                if type(mod) == "table" then
                    assert.is_function(mod.opts,
                        mod_name .. " should have opts() function")
                end
            end
        end)

        it("before() function modules should expose before function", function()
            for _, mod_name in ipairs(before_function_modules) do
                local ok, mod = pcall(require, mod_name)
                assert.is_true(ok, "Failed to load " .. mod_name)
                if type(mod) == "table" then
                    assert.is_function(mod.before,
                        mod_name .. " should have before() function")
                end
            end
        end)

        it("opts() functions should return tables", function()
            for _, mod_name in ipairs(opts_function_modules) do
                local ok, mod = pcall(require, mod_name)
                if ok and type(mod) == "table" and mod.opts then
                    local opts_result = mod.opts()
                    assert.is_table(opts_result,
                        mod_name .. ".opts() should return a table")
                end
            end
        end)
    end)
end)
