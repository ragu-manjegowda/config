-- References
-- https://github.com/zhuorantan/dotfiles
-- https://github.com/LunarVim/LunarVim
require "user.options"
require "user.keymaps"
require "user.autocommands"
require "user.colorscheme"
require "user.buf-only"

require("user.bootstrap").init()

local plugins = require "user.plugins-table"
require("user.bootstrap").load { plugins }

