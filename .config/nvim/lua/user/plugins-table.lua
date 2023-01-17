-- Autocommand that reloads neovim whenever you save the plugins-table.lua file
vim.cmd [[
    augroup packer_user_config
        autocmd!
        autocmd BufWritePost plugins-table.lua source <afile> | PackerSync
    augroup end
]]

local core_plugins = {
    -- Color scheme
    { "Tsuzat/NeoSolarized.nvim" },

    -- cmp plugins
    {
        "hrsh7th/nvim-cmp",
        requires = {
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
        config = [[require("user.nvim-cmp").config()]],
    },

    -- Code Browsing
    {
        "skywind3000/gutentags_plus",
        requires = { "ludovicchabant/vim-gutentags" },
        config = [[require("user.gutentags-plus").config()]],
    },

    { "derekwyatt/vim-fswitch" },

    {
        "preservim/tagbar",
        setup = [[require("user.tagbar").before()]],
    },

    -- Compile
    {
        "tpope/vim-dispatch"
    },

    -- Debugging
    {
        "rcarriga/nvim-dap-ui",
        requires = {
            {
                "mfussenegger/nvim-dap",
                config = [[require("user.dap").config()]],
                requires = {
                    "WhoIsSethDaniel/mason-tool-installer.nvim",
                },
            },
            "theHamsta/nvim-dap-virtual-text",
        },
        config = [[require("user.dapui").config()]],
    },

    -- Extra
    { "mbbill/undotree" },

    {
        "windwp/windline.nvim",
        config = [[require("user.windline").config()]],
    },

    {
        "nvim-tree/nvim-tree.lua",
        requires = { "nvim-tree/nvim-web-devicons" },
        config = [[require("user.nvim-tree").config()]],
    },

    { "itchyny/vim-cursorword" },

    {
        "folke/which-key.nvim",
        setup = [[require("user.which-key").before()]],
        config = [[require("user.which-key").config()]],
    },

    { "junegunn/vim-peekaboo" },

    {
        "Yggdroot/indentLine",
        setup = [[require("user.indent-line").before()]],
    },

    {
        "numToStr/FTerm.nvim",
        config = [[require("user.fterm").config()]],
    },

    { "ggandor/lightspeed.nvim" },

    {
        "edluffy/specs.nvim",
        setup = [[require("user.specs").before()]],
        config = [[require("user.specs").config()]],
    },

    {
        "Rasukarusan/nvim-select-multi-line",
        setup = [[require("user.nvim-select-multi-line").before()]],
    },

    { "lambdalisue/suda.vim" },

    {
        "nanozuki/tabby.nvim",
        config = [[require("user.tabby").config()]],
    },

    -- Git
    {
        "tpope/vim-fugitive",
        config = [[require("user.fugitive").config()]],
    },

    {
        "lewis6991/gitsigns.nvim",
        config = [[require("user.gitsigns").config()]],
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        requires = {
            "hrsh7th/nvim-cmp",
            "p00f/clangd_extensions.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = [[require("user.lspconfig").config()]],
    },

    -- LSP Saga
    {
        "glepnir/lspsaga.nvim",
        branch = "main",
        requires = {
            "Tsuzat/NeoSolarized.nvim",
            "neovim/nvim-lspconfig"
        },
        config = [[require("user.lspsaga").config()]],
    },

    {
        "folke/lsp-colors.nvim",
        config = [[require("user.lsp-colors").config()]],
    },

    {
        "folke/neodev.nvim",
        requires = {
            "neovim/nvim-lspconfig"
        },
        config = function()
            require("neodev").setup()
        end
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
        requires = {
            "williamboman/mason.nvim",
            config = [[require("user.mason").config()]],
        },
        config = [[require("user.mason-tool-installer").config()]],
    },

    -- Packer
    { "wbthomason/packer.nvim" },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        requires = {
            "nvim-lua/popup.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-dap.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                run = "make",
            },
            "nvim-telescope/telescope-hop.nvim",
            "nvim-telescope/telescope-live-grep-args.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        setup = [[require("user.telescope").before()]],
        config = [[require("user.telescope").config()]],
    },


    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        requires = {
            "nvim-treesitter/nvim-treesitter",
            run = ":TSUpdate",
            config = [[require("user.treesitter").config()]],
        },
        config = [[require("user.treesitter-textobjects").config()]],
    },

    -- Vim Session
    {
        "xolox/vim-session",
        requires = {
            "xolox/vim-misc",
        },
        setup = [[require("user.vim-session").before()]],
    },

    -- Vim in browser
    {
        "glacambre/firenvim",
        run = function()
            vim.fn["firenvim#install"](0)
        end,
        config = [[require("user.firenvim").config()]],
    }
}

return core_plugins
