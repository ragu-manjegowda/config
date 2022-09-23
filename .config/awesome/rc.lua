-- ░█▀▀░█░█░█▀▄░█▀▄░█▀▀░█▀█░█░░
-- ░▀▀█░█░█░█▀▄░█▀▄░█▀▀░█▀█░█░░
-- ░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀
-- Banner generated using `toilet -f pagga AwesomeWM"

local gears = require('gears')
local beautiful = require('beautiful')
local awful = require('awful')
local naughty = require('naughty')
local revelation = require("library.revelation")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup!" or "!"),
        message = message
    }
end
-- }}}

-- ░█▀▀░█░█░█▀▀░█░░░█░░
-- ░▀▀█░█▀█░█▀▀░█░░░█░░
-- ░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀

awful.util.shell = 'sh'

-- ░▀█▀░█░█░█▀▀░█▄█░█▀▀
-- ░░█░░█▀█░█▀▀░█░█░█▀▀
-- ░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀

beautiful.init(require('theme'))
revelation.init()

-- ░█░░░█▀█░█░█░█▀█░█░█░▀█▀
-- ░█░░░█▀█░░█░░█░█░█░█░░█░
-- ░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░░▀░

require('layout')

-- ░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀░█░█░█▀▄░█▀█░▀█▀░▀█▀░█▀█░█▀█░█▀▀
-- ░█░░░█░█░█░█░█▀▀░░█░░█░█░█░█░█▀▄░█▀█░░█░░░█░░█░█░█░█░▀▀█
-- ░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀

require('configuration.client')
-- require('configuration.root')
require('configuration.tags')
root.keys(require('configuration.keys.global'))

-- ░█▄█░█▀█░█▀▄░█░█░█░░░█▀▀░█▀▀
-- ░█░█░█░█░█░█░█░█░█░░░█▀▀░▀▀█
-- ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀▀▀░▀▀▀░▀▀▀

require('module.notifications')
require('module.auto-start')
require('module.exit-screen')
require('module.titlebar')
require('module.brightness-osd')
require('module.kbd-brightness-osd')
require('module.volume-osd')
require('module.lockscreen')
require('module.dynamic-wallpaper')

-- ░█░█░█▀█░█░░░█░░░█▀█░█▀█░█▀█░█▀▀░█▀▄
-- ░█▄█░█▀█░█░░░█░░░█▀▀░█▀█░█▀▀░█▀▀░█▀▄
-- ░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀░░░▀▀▀░▀░▀

screen.connect_signal(
	'request::wallpaper',
	function(s)
		-- If wallpaper is a function, call it with the screen
		if beautiful.wallpaper then
			if type(beautiful.wallpaper) == 'string' then

				-- Check if beautiful.wallpaper is color/image
				if beautiful.wallpaper:sub(1, #'#') == '#' then
					-- If beautiful.wallpaper is color
					gears.wallpaper.set(beautiful.wallpaper)

				elseif beautiful.wallpaper:sub(1, #'/') == '/' then
					-- If beautiful.wallpaper is path/image
					gears.wallpaper.maximized(beautiful.wallpaper, s)
				end
			else
				beautiful.wallpaper(s)
			end
		end
	end
)

-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ██ ▄▄ █ ▄▄▀█ ▄▄▀█ ▄▄▀█ ▄▄▀█ ▄▄▄█ ▄▄████ ▄▄▀█▀▄▄▀█ ██ ██ ▄▄█▀▄▀█▄ ▄█▀▄▄▀█ ▄▄▀
-- ██ █▀▀█ ▀▀ █ ▀▀▄█ ▄▄▀█ ▀▀ █ █▄▀█ ▄▄████ ████ ██ █ ██ ██ ▄▄█ █▀██ ██ ██ █ ▀▀▄
-- ██ ▀▀▄█▄██▄█▄█▄▄█▄▄▄▄█▄██▄█▄▄▄▄█▄▄▄████ ▀▀▄██▄▄██▄▄█▄▄█▄▄▄██▄███▄███▄▄██▄█▄▄
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

collectgarbage("setpause", 160)
collectgarbage("setstepmul", 400)

gears.timer.start_new(10, function()
  collectgarbage("step", 20000)
  return true
end)


-- ______          _                   _____
-- | ___ \        | |                 |_   _|
-- | |_/ /___  ___| |_ ___  _ __ ___    | | __ _  __ _
-- |    // _ \/ __| __/ _ \| '__/ _ \   | |/ _` |/ _` |
-- | |\ \  __/\__ \ || (_) | | |  __/   | | (_| | (_| |
-- \_| \_\___||___/\__\___/|_|  \___|   \_/\__,_|\__, |
--                                                __/ |
--                                               |___/

local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

ws_fname = utils_dir .. "/awesome-last-ws"

function save_current_tag()
  local f = assert(io.open(ws_fname, "w"))
  local t = client.focus and client.focus.first_tag or nil
  if t ~= nil then
    f:write(t.name, "\n")
  end
  f:close()
end

function load_last_active_tag()
local f = assert(io.open(ws_fname, "r"))
tag_name = f:read("*line")
f:close()
local t = awful.tag.find_by_name(nil, tag_name)
  if t ~= nil then
    awful.tag.viewnone()
    awful.tag.viewtoggle(t)
  end
end

awesome.connect_signal("exit", function (c)
    if c == true then
        -- We are about to restart awesome, save our last used tag
        save_current_tag()
    end
end)

load_last_active_tag()
