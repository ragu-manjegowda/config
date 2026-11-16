local config_dir = assert(os.getenv('GUI_CONFIG')) .. '/'
package.path = config_dir .. '?.lua;' .. config_dir .. '?/init.lua;' .. package.path
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local json = require('library.json')
local filesystem = gears.filesystem
filesystem.get_configuration_dir = function() return config_dir end
local profile = os.getenv('GUI_PROFILE') or 'config.lua'
local config = dofile(config_dir .. 'configuration/' .. profile)
config.display.dpi = tonumber(assert(os.getenv('GUI_DPI')))
package.loaded['configuration.config'] = config
config.widget.stocks.symbols = { 'GUI_FIRST', 'GUI_SECOND', 'GUI_THIRD', 'GUI_FOURTH', 'GUI_LAST' }
config.widget.email.address = 'fixture@example.invalid'
config.widget.email.app_password = ''
config.widget.weather.key = 'gui-fixture-key'
config.widget.weather.open_weather = config.widget.weather.open_weather or {}
config.widget.weather.open_weather.key = 'gui-fixture-key'
local fixture = {
    scenario = os.getenv('GUI_SCENARIO') or 'success',
    volume = 42,
    brightness = 60,
    requests = {},
    errors = {},
    targets = {},
    events = {}
}
_G.gui_test = fixture
awesome.connect_signal('debug::error', function(error) fixture.errors[#fixture.errors + 1] = tostring(error) end)
local readable, executable = filesystem.file_readable, filesystem.file_executable
filesystem.file_readable = function(filename)
    if filename:match('^/sys/') then return fixture.scenario == 'success' end
    return readable(filename)
end
filesystem.file_executable = function(filename)
    if filename == '/usr/bin/powerprofilesctl' then return fixture.scenario == 'success' end
    return executable(filename)
end

local function request(command, callback)
    local arguments = type(command) == 'table' and command or { command }
    local text = table.concat(arguments, ' ')
    fixture.requests[#fixture.requests + 1] = text
    local stdout, stderr, code = '', '', 0
    local failing = fixture.scenario == 'offline'
    if text:find('audio%-control') then
        local action = text:match('%-%-action ([^ ]+)')
        if not failing and action == 'set' then fixture.volume = tonumber(text:match('%-%-value ([^ ]+)')) end
        stdout = json.stringify({
            available = not failing,
            volume = fixture.volume,
            muted = false,
            description = failing and 'Fixture device unavailable' or 'Fixture speaker',
            percent = fixture.volume
        })
    elseif text:find('display%-control') then
        if failing then
            code, stderr = 1, 'Fixture display unavailable'
        else
            local value = text:match('%-S (%d+)')
            if value then fixture.brightness = tonumber(value) end
            stdout = tostring(fixture.brightness)
        end
    elseif text:find('api.open%-meteo.com') then
        stdout = (failing or fixture.scenario == 'fallback') and 'error' or json.stringify({
            current = {
                temperature_2m = 24, weather_code = 0, is_day = 1 },
            daily = {
                sunrise = { '2026-01-01T06:30' }, sunset = { '2026-01-01T18:30' } }
        })
    elseif text:find('wttr.in', 1, true) and fixture.scenario == 'fallback' then
        stdout = json.stringify({
            current_condition = { {
                temp_C = '19',
                weatherCode = '113',
                weatherDesc = { { value = 'Fixture fallback sunshine' } }
            } }
        })
    elseif text:find('wttr.in', 1, true) or text:find('api.openweathermap.org', 1, true) then
        stdout, code = 'error', 1
    elseif text:find('stocks_fetcher.sh', 1, true) then
        stdout = json.stringify(failing and { error = 'Fixture service unavailable' } or {
            symbol = arguments[#arguments]:match('([^ ]+)$'), price = 123.45, change = 1.25, change_percent = 1.02 })
    elseif text:find('widget/email/mails.txt', 1, true) then
        if failing then
            stdout = 'Temporary failure in name resolution'
        else
            stdout = 'Unread Count: 8\n'
            for index = 1, 8 do
                stdout = stdout .. 'From: Fixture ' .. index .. ' <fixture@example.invalid>\nSubject: ' ..
                    'Long GUI subject & Unicode café ' .. index .. ' ' .. string.rep('content ', 10) ..
                    '\nLocal Date: 2026-01-01 12:00\n'
            end
        end
    elseif text:find('outlook%-calendar') then
        stdout = json.stringify(failing and { ok = false, error = 'Fixture calendar offline' } or
        { ok = true, events = {} })
    elseif text:find('picom.conf', 1, true) then
        stdout = text:find('strength', 1, true) and '5' or 'methodnone'
    elseif text:find('rfkill', 1, true) then
        stdout = '0: hci0: Bluetooth\n\tSoft blocked: no\n\tHard blocked: no\n'
    elseif text:find('utilities/display/blue-light', 1, true) then
        stdout = 'off'
    elseif text:find('power%-profile') then
        stdout = 'balanced'
    elseif text:find('utilities/network/prisma-vpn-status', 1, true) then
        stdout = 'disconnected none'
    elseif text:find('utilities/input/read-kbd-battery', 1, true) then
        stdout = 'disconnected'
    elseif text:find('getent passwd', 1, true) then
        stdout = 'GUI Fixture User'
    elseif text:find('utilities/desktop/profile-image', 1, true) then
        stdout = 'default'
    elseif text:find('canberra-gtk-play', 1, true) then
        stdout = ''
    elseif text:find('pkill', 1, true) and text:find('pactl subscribe', 1, true) then
        stdout = ''
    elseif text == 'kill -TERM 999999' then
        stdout = ''
    elseif text:find('mkdir %-p ') then
        stdout = ''
    elseif text:find('/usr/bin/stat', 1, true) then
        stdout = tostring(os.time())
    else
        code, stderr = 127, 'Unexpected GUI fixture command: ' .. text
        fixture.errors[#fixture.errors + 1] = stderr
    end
    if callback then
        gears.timer.start_new(fixture.scenario == 'slow' and 0.35 or 0.01, function()
            callback(stdout, stderr, 'exit', code)
            fixture.completed = (fixture.completed or 0) + 1
            return false
        end)
    end
    return 999999
end

awful.spawn.easy_async = request
awful.spawn.easy_async_with_shell = request
awful.spawn.with_shell = request
awful.spawn.with_line_callback = function(command)
    if table.concat(command, ' ') ~= 'pactl subscribe' then request(command) end
    return 999999
end
getmetatable(awful.spawn).__call = function(_, command) return request(command) end
beautiful.xresources.set_dpi(config.display.dpi)
for display in screen do beautiful.xresources.set_dpi(config.display.dpi, display) end
beautiful.init(require('theme'))
gears.wallpaper.set('#203040')
local actual_switch = require('widget.control-center-switch')
package.loaded['widget.control-center-switch'] = function(...)
    local widget = actual_switch(...)
    fixture.targets.mode_switch = widget
    return widget
end
local control_center = require('layout.control-center')
local info_center = require('layout.info-center')
fixture.targets.email_section = require('widget.email')
fixture.targets.stocks_section = require('widget.stocks')
fixture.targets.weather_section = require('widget.weather')
awful.screen.connect_for_each_screen(function(display)
    awful.tag({ 'GUI' }, display, awful.layout.suit.tile)
    display.top_panel = awful.wibar { position = 'top', screen = display,
        height = beautiful.xresources.apply_dpi(46), bg = beautiful.background }
    display.control_center = control_center(display)
    display.info_center = info_center(display)
    for _, name in ipairs({ 'control_center', 'info_center' }) do
        for _, event in ipairs({ 'opened', 'closed' }) do
            display[name]:connect_signal(event, function()
                fixture.events[#fixture.events + 1] = name .. ':' .. event
            end)
        end
    end
end)
root.keys(require('configuration.keys.global'))
for _, binding in ipairs(root.keys()) do
    binding:connect_signal('press', function()
        fixture.events[#fixture.events + 1] = 'key:' .. binding.key
    end)
end

local function panel_snapshot(panel)
    local result = panel:geometry()
    result.visible = panel.visible
    result.widgets = {}
    local identities = {}
    for _, identifier in ipairs({ 'volume_slider', 'brightness_slider', 'main_control', 'monitor_control' }) do
        local widget = panel.widget:get_children_by_id(identifier)[1]
        if widget then identities[widget] = identifier end
    end
    for _, name in ipairs({ 'volume', 'brightness' }) do
        local identifier = name .. '_slider'
        for _, widget in ipairs(require('widget.' .. name .. '-slider'):get_all_children()) do
            if widget.get_value and widget.set_value then identities[widget] = identifier end
        end
    end
    for identifier, widget in pairs(fixture.targets) do identities[widget] = identifier end
    local function visit(node)
        local widget = node:get_widget()
        local width, height = node:get_size()
        local x, y = node:get_matrix_to_device():transform_point(0, 0)
        local item = {
            x = x + panel.x,
            y = y + panel.y,
            width = width,
            height = height,
            visible = widget.visible ~= false,
            id = identities[widget]
        }
        if widget.get_text then
            local success, text = pcall(widget.get_text, widget)
            if success then item.text = text end
        end
        if item.id or item.text then result.widgets[#result.widgets + 1] = item end
        for _, child in ipairs(node:get_children()) do visit(child) end
    end
    if panel._drawable._widget_hierarchy then visit(panel._drawable._widget_hierarchy) end
    return result
end

function fixture.dump()
    local display = awful.screen.focused()
    local sections = {}
    for _, name in ipairs({ 'email', 'stocks', 'calendar-events', 'weather' }) do
        local widget = require('widget.' .. name)
        sections[name] = widget.get_viewport_height and widget:get_viewport_height() or -1
    end
    local output = assert(io.open(assert(os.getenv('GUI_STATE')), 'w'))
    output:write(json.stringify({
        control = panel_snapshot(display.control_center),
        info = panel_snapshot(display.info_center),
        screen = display.geometry,
        workarea = display.workarea,
        dpi = beautiful.xresources.get_dpi(display),
        gap = beautiful.useless_gap or 0,
        sections = sections,
        volume = fixture.volume,
        brightness = fixture.brightness,
        ready = not awesome.startup,
        events = fixture.events,
        key_count = #root.keys(),
        requests = fixture.requests,
        completed = fixture.completed or 0,
        errors = fixture.errors,
        machine = require('library.machine')
    }))
    output:close()
end

gears.timer.delayed_call(fixture.dump)
