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
        title   = "Oops, an error happened" .. (startup and " during startup!" or "!"),
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
require('module.brightness-osd')
require('module.kbd-brightness-osd')
require('module.volume-osd')
require('module.mic-osd')
require('module.lockscreen')
require('module.dynamic-wallpaper')
require('module.screen-manager') -- Handle monitor connect/disconnect gracefully

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

---@diagnostic disable-next-line: param-type-mismatch
collectgarbage("setpause", 160)
---@diagnostic disable-next-line: param-type-mismatch
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

_G.ws_fname = utils_dir .. "/awesome-last-ws"

local save_current_tag = function()
    -- Get the currently selected tag from mouse screen (more reliable than focused)
    local s = mouse.screen
    local t = s.selected_tag

    -- Write to file: save both tag name and screen index
    local f = assert(io.open(ws_fname, "w"))
    if t ~= nil then
        -- Save format: "tag_name|screen_index"
        f:write(t.name .. "|" .. s.index, "\n")
    end
    f:close()
end

local load_last_active_tag = function()
    local f = io.open(ws_fname, "r")
    if not f then
        return -- File doesn't exist yet
    end
    local saved_line = f:read("*line")
    f:close()

    if not saved_line then
        return -- No data saved
    end

    -- Parse saved data: "tag_name|screen_index"
    local tag_name, screen_idx = saved_line:match("^(.+)|(%d+)$")

    -- If old format (just tag name without screen index), use it as-is
    if not tag_name then
        tag_name = saved_line
        screen_idx = nil
    else
        screen_idx = tonumber(screen_idx)
    end

    -- Try to find the tag on the specific screen if we have screen index
    local t = nil
    if screen_idx and screen_idx <= screen:count() then
        local target_screen = screen[screen_idx]
        if target_screen and target_screen.valid then
            t = awful.tag.find_by_name(target_screen, tag_name)
        end
    end

    -- Fallback: try to find tag on any screen
    if not t then
        t = awful.tag.find_by_name(nil, tag_name)
    end

    -- Last fallback: try primary screen
    if not t or not t.screen or not t.screen.valid then
        t = awful.tag.find_by_name(screen.primary, tag_name)
    end

    if t ~= nil then
        awful.tag.viewnone(t.screen)
        awful.tag.viewtoggle(t)
    end
end

awesome.connect_signal("exit", function(reason_restart)
    -- Save on any exit (restart or logout)
    -- reason_restart is true when restarting, false when exiting
    save_current_tag()
end)

load_last_active_tag()
