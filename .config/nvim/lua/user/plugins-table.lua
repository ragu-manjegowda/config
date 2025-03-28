-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local core_plugins = {
    {
        "folke/lazy.nvim",
        tag = "stable"
    },

    -- Debugging
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            {
                "mfussenegger/nvim-dap",
                config = function()
                    require("user.dap").config()
                end,
                dependencies = {
                    "WhoIsSethDaniel/mason-tool-installer.nvim",
                }
            },
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            require("user.dapui").config()
        end,
        event = "VeryLazy"
    },

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("user.nvim-tree").config()
        end
    },

    {
        "folke/which-key.nvim",
        init = function()
            require("user.which-key").before()
        end,
        config = function()
            require("user.which-key").config()
        end,
        event = "VeryLazy"
    },

    -- Terminal
    {
        "numToStr/FTerm.nvim",
        config = function()
            require("user.fterm").config()
        end
    },

    {
        "willothy/flatten.nvim",
        -- Ensure that it runs first to minimize delay when opening file
        -- from terminal
        lazy = false,
        opts = require("user.flatten").opts(),
        priority = 1001
    },

    { "lambdalisue/suda.vim" },

    -- Git
    {
        "tpope/vim-fugitive",
        config = function()
            require("user.fugitive").config()
        end
    },

    -- Package management
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            config = function()
                require("user.mason").config()
            end
        },
        config = function()
            require("user.mason-tool-installer").config()
        end
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("user.lualine").config()
        end,
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },

    -- Tabline
    {
        "akinsho/bufferline.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("user.bufferline").config()
        end,
        event = "VeryLazy"
    },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/popup.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-dap.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
            "nvim-telescope/telescope-hop.nvim",
            "nvim-telescope/telescope-live-grep-args.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "debugloop/telescope-undo.nvim"
        },
        init = function()
            require("user.telescope").before()
        end,
        config = function()
            require("user.telescope").config()
        end,
        event = "UIEnter"
    }
}

local extra_plugins = {
    core_plugins,

    -- Codeium
    {
        "monkoose/neocodeium",
        config = function()
            require("user.neocodeium").config()
        end,
        event = "VeryLazy"
    },

    -- cmp plugins
    {
        "hrsh7th/nvim-cmp",
        config = function()
            require("user.nvim-cmp").config()
        end,
        dependencies = {
            "alexander-born/cmp-bazel",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            "hrsh7th/cmp-omni",
            "hrsh7th/cmp-path",
            "onsails/lspkind-nvim",
            "quangnguyen30192/cmp-nvim-tags"
        }
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "lvimuser/lsp-inlayhints.nvim",
                config = function()
                    require("lsp-inlayhints").setup()
                end
            },
            "ray-x/lsp_signature.nvim"
        },
        config = function()
            require("user.lspconfig").config()
        end,
        event = "VimEnter"
    },

    -- LSP Saga
    {
        "nvimdev/lspsaga.nvim",
        branch = "main",
        dependencies = {
            "neovim/nvim-lspconfig"
        },
        config = function()
            require("user.lspsaga").config()
        end,
        event = "VimEnter"
    },

    {
        "Mofiqul/trld.nvim",
        config = function()
            require("trld").setup()
        end
    },

    -- Vim Session
    {

        "Shatur/neovim-session-manager",
        dependencies = {
            "nvim-lua/plenary.nvim"
        },
        init = function()
            require("user.neovim-session-manager").config()
        end,
        event = "VeryLazy"
    }
}

local all_plugins = {
    extra_plugins,

    -- Bazel
    {
        "alexander-born/bazel.nvim",
        init = function()
            require("user.bazel").before()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-lua/plenary.nvim"
        },
        event = "VeryLazy"
    },

    -- Code Browsing
    -- {
    --     "skywind3000/gutentags_plus",
    --     dependencies = { "ludovicchabant/vim-gutentags" },
    --     config = function()
    --         require("user.gutentags-plus").config()
    --     end
    -- },

    { "derekwyatt/vim-fswitch" },

    -- Compile
    {
        "tpope/vim-dispatch"
    },

    -- Cursor animation
    {
        "gen740/SmoothCursor.nvim",
        config = function()
            require("user.smoothcursor").config()
        end
    },

    -- Extras
    {
        "echasnovski/mini.bracketed",
        event = "VeryLazy",
        config = function()
            require("user.bracketed").config()
        end,
        version = false
    },

    {
        "echasnovski/mini.files",
        config = function()
            require("user.files").config()
        end,
        event = "VeryLazy",
        version = false
    },

    { "itchyny/vim-cursorword" },

    -- Indent markers
    {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("user.indent-blankline").config()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        event = "UIEnter",
        main = "ibl"
    },

    {
        "Rasukarusan/nvim-select-multi-line",
        init = function()
            require("user.nvim-select-multi-line").before()
        end
    },

    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("user.gitsigns").config()
        end
    },

    {
        "sindrets/diffview.nvim",
        event = "VeryLazy"
    },

    {
        "folke/noice.nvim",
        config = function()
            require("user.noice").config()
        end,
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        }
    },

    -- Markdown preview
    {
        "OXY2DEV/markview.nvim",
        config = function()
            require("user.markview").config()
        end,
        dependencies = {
            "3rd/image.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
        ft = "markdown"
    },

    -- Image preview
    {
        "3rd/image.nvim",
        config = function()
            require("user.image").config()
        end,
        dependencies = {
            'leafo/magick',
        },
        event = "VeryLazy"
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects"
        },
        build = ":TSUpdate",
        config = function()
            require("user.treesitter").config()
        end
    },

    {
        "HiPhish/rainbow-delimiters.nvim",
        config = function()
            require("user.rainbow-delimiters").config()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter"
        },
        priority = 1001
    },

    -- Copy/setup nvim on remote machine as appimage
    {
        "amitds1997/remote-nvim.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",         -- For standard functions
            "MunifTanjim/nui.nvim",          -- To build the plugin UI
            "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
        },
        config = function()
            require("user.remote-nvim").config()
        end,
    },

    -- Use vim efficiently
    {
        "m4xshen/hardtime.nvim",
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {}
    },

    -- Peek before jump
    {
        "nacro90/numb.nvim",
        event = "CmdlineEnter",
        opts = {}
    },

    -- LLMs
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            {
                "nvim-lua/plenary.nvim"
            }
        },
        event = "VeryLazy",
        opts = require("user.codecompanion").opts()
    },

    {
        "yetone/avante.nvim",
        build = "make",
        dependencies = {
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = require("user.avante").img_clip_opts()
            }
        },
        event = "VeryLazy",
        opts = require("user.avante").opts(),
        version = false
    }
}

-------------------------------------------------------------------------------
-- Check if we need to load all plugins
-- Workaround for disabling plugins known to slow down neovim on certain files
--
--   vim --cmd "+lua vim.g.blazing_fast = 0" -- load all plugins
--   vim --cmd "+lua vim.g.blazing_fast = 1" -- load core + extra plugins
--   vim --cmd "+lua vim.g.blazing_fast = 2" -- load core plugins only
--   vim -u NORC                             -- do not load user config
--   vim --noplugin                          -- do not load plugins
--
-------------------------------------------------------------------------------
if vim.g.blazing_fast == 1 then
    return extra_plugins
elseif vim.g.blazing_fast == 2 then
    -- Set options to make nvim faster
    local options = {
        foldmethod = "manual",
        list = false,
        swapfile = false,
        syntax = "disable",
        undolevels = -1,
        undoreload = 0
    }
    for k, v in pairs(options) do
        vim.opt[k] = v
    end

    return core_plugins
else
    return all_plugins
end
