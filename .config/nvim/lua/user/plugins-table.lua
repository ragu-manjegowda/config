-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local core_plugins = {
    {
        "folke/lazy.nvim",
        tag = "stable"
    },

    -- cmp plugins
    {
        "hrsh7th/nvim-cmp",
        config = function()
            require("user.nvim-cmp").config()
        end,
        dependencies = {
            "quangnguyen30192/cmp-nvim-tags",
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
        end
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

    -- Extras
    {
        'echasnovski/mini.bracketed',
        event = "VeryLazy",
        config = function()
            require('user.bracketed').config()
        end,
        version = false
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
        "aaronhallaert/advanced-git-search.nvim",
        config = function()
            require("telescope").load_extension("advanced_git_search")
        end,
        dependencies = {
            "nvim-telescope/telescope.nvim",
            -- to show diff splits and open commits in browser
            "tpope/vim-fugitive"
        },
        event = "UIEnter"
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
        -- Lazy load firenvim
        -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
        cond = not not vim.g.started_by_firenvim,
        build = function()
            vim.fn["firenvim#install"](0)
        end,
        config = function()
            require("lazy").load({ plugins = "firenvim", wait = true })
            require("user.firenvim").config()
        end
    }
}

return core_plugins
