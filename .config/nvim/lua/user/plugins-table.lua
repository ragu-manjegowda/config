-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local core_plugins = {
    { "folke/lazy.nvim", tag = "stable" },

    -- cmp plugins
    {
        "hrsh7th/nvim-cmp",
        config = function()
            require("user.nvim-cmp").config()
        end,
        dependencies = {
            "L3MON4D3/LuaSnip",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            "hrsh7th/cmp-omni",
            "hrsh7th/cmp-path",
            "onsails/lspkind-nvim",
            "rafamadriz/friendly-snippets",
            "saadparwaiz1/cmp_luasnip"
        }
    },

    -- Code Browsing
    {
        "skywind3000/gutentags_plus",
        dependencies = { "ludovicchabant/vim-gutentags" },
        config = function()
            require("user.gutentags-plus").config()
        end,
        event = "VeryLazy"
    },

    { "derekwyatt/vim-fswitch" },

    {
        "preservim/tagbar",
        init = function()
            require("user.tagbar").before()
        end
    },

    -- Codeium
    {
        "Exafunction/codeium.vim",
        init = function()
            require("user.codeium").before()
        end,
        event = { "InsertEnter" },
    },

    -- Compile
    {
        "tpope/vim-dispatch"
    },

    -- Cursor animation
    { "gen740/SmoothCursor.nvim",
        config = function()
            require("user.smoothcursor").config()
        end
    },

    {
        "edluffy/specs.nvim",
        init = function()
            require("user.specs").before()
        end,
        config = function()
            require("user.specs").config()
        end
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
        end,
        event = "VeryLazy"
    },

    { "itchyny/vim-cursorword" },

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

    { "junegunn/vim-peekaboo" },

    -- Indent markers
    {
        -- Used only for the sake of indent objects ]i, [i, ai, ii
        'echasnovski/mini.indentscope',
        event = "VeryLazy",
        config = function()
            require('user.indentscope').config()
        end,
        version = false
    },

    {
        "lukas-reineke/indent-blankline.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        event = "UIEnter",
        init = function()
            require("user.indent-blankline").before()
        end,
        config = function()
            require("user.indent-blankline").config()
        end
    },

    {
        "numToStr/FTerm.nvim",
        config = function()
            require("user.fterm").config()
        end
    },

    {
        "Rasukarusan/nvim-select-multi-line",
        init = function()
            require("user.nvim-select-multi-line").before()
        end
    },

    { "lambdalisue/suda.vim" },

    -- Git
    {
        "tpope/vim-fugitive",
        config = function()
            require("user.fugitive").config()
        end
    },

    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("user.gitsigns").config()
        end
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "p00f/clangd_extensions.nvim",
        },
        config = function()
            require("user.lspconfig").config()
        end,
        event = "BufReadPre"
    },

    -- LSP Saga
    {
        "glepnir/lspsaga.nvim",
        branch = "main",
        dependencies = {
            "neovim/nvim-lspconfig"
        },
        config = function()
            require("user.lspsaga").config()
        end,
        event = "BufRead"
    },

    {
        "Mofiqul/trld.nvim",
        config = function()
            require("trld").setup()
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

    -- Performance
    {
        "LunarVim/bigfile.nvim",
        init = function()
            require("user.bigfile").setup()
        end,
        event = "VeryLazy"
    },

    -- Status line
    {
        "windwp/windline.nvim",
        dependencies = {
            "jcdickinson/wpm.nvim",
            config = function()
                require("wpm").setup({})
            end
        },
        config = function()
            require("user.windline").config()
        end
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
            "debugloop/telescope-undo.nvim"
        },
        init = function()
            require("user.telescope").before()
        end,
        config = function()
            require("user.telescope").config()
        end,
        event = "UIEnter"
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            lazy = true,
        },
        build = ":TSUpdate",
        config = function()
            require("user.treesitter").config()
        end,
        event = "BufRead"
    },

    -- Vim Session
    {
        "xolox/vim-session",
        dependencies = {
            "xolox/vim-misc",
            event = "VeryLazy"
        },
        init = function()
            require("user.vim-session").before()
        end,
        event = "VeryLazy"
    },

    -- Vim in browser
    {
        "glacambre/firenvim",
        build = function()
            vim.fn["firenvim#install"](0)
        end,
        config = function()
            require("user.firenvim").config()
        end
    }
}

return core_plugins
