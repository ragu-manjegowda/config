local core_plugins = {
    -- cmp plugins
    {
        "hrsh7th/nvim-cmp",
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
        },
        config = function()
            require("user.nvim-cmp").config()
        end,
        event = "VeryLazy"
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
        end
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
        end
    },

    -- Extra
    { "mbbill/undotree" },

    {
        "windwp/windline.nvim",
        config = function()
            require("user.windline").config()
        end
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
        end
    },

    { "junegunn/vim-peekaboo" },

    {
        "Yggdroot/indentLine",
        init = function()
            require("user.indent-line").before()
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

    {
        "nanozuki/tabby.nvim",
        config = function()
            require("user.tabby").config()
        end
    },

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
            "hrsh7th/nvim-cmp",
            "p00f/clangd_extensions.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            require("user.lspconfig").config()
        end,
        lazy = true
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
        event = "VeryLazy"
    },

    {
        "folke/neodev.nvim",
        dependencies = {
            "neovim/nvim-lspconfig"
        },
        config = function()
            require("neodev").setup()
        end,
        event = "VeryLazy"
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

    -- Packer
    { "wbthomason/packer.nvim" },

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
        },
        init = function()
            require("user.telescope").before()
        end,
        config = function()
            require("user.telescope").config()
        end,
        event = "VeryLazy"
    },


    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            config = function()
                require("user.treesitter").config()
            end
        },
        config = function()
            require("user.treesitter-textobjects").config()
        end,
        lazy = true
    },

    -- Vim Session
    {
        "xolox/vim-session",
        dependencies = {
            "xolox/vim-misc",
        },
        init = function()
            require("user.vim-session").before()
        end,
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
