local awful = require('awful')
local gears = require('gears')
local json = require('library.json')
local config = require('configuration.config')
local display_brightness = require('library.display-brightness')
local helper = gears.filesystem.get_configuration_dir() .. 'utilities/desktop/audio-control'
local M = { output = display_brightness.output }
local queue, active = {}, nil
local timer

function M.scope(output)
    return output == config.display.primary.name and 'primary' or 'external'
end

local function command(output, kind, action, value)
    local audio = config.widget.audio or {}
    local scope = M.scope(output)
    local pattern = scope == 'primary' and audio.primary_device_pattern or audio.external_device_pattern
    local argv = { '/usr/bin/python3', helper, '--kind', kind, '--scope', scope,
        '--device-pattern', pattern or '', '--external-pattern', audio.external_device_pattern or '',
        '--action', action }
    if value then
        argv[#argv + 1] = '--value'; argv[#argv + 1] = tostring(value)
    end
    return argv
end

local function decode(stdout)
    local ok, value = pcall(json.parse, stdout)
    if ok and type(value) == 'table' then return value end
    return { available = false, description = 'Unable to read audio status' }
end

function M.pending(output, kind)
    if active and active.output == output and active.kind == kind then return true end
    for _, item in ipairs(queue) do
        if item.output == output and item.kind == kind then return true end
    end
    return false
end

function M.read(output, kind, callback)
    awful.spawn.easy_async(command(output, kind, 'status'), function(stdout, _, _, code)
        local state = code == 0 and decode(stdout) or { available = false, description = 'Audio query failed' }
        callback(state)
    end)
end

local function apply_next()
    if active or #queue == 0 then return end
    local item = table.remove(queue, 1)
    active = item
    awful.spawn.easy_async(command(item.output, item.kind, item.action, item.value),
        function(stdout, stderr, _, code)
            active = nil
            local state = decode(stdout)
            awesome.emit_signal('widget::audio:changed', item.output, item.kind, state)
            if code ~= 0 and stderr ~= '' then gears.debug.print_warning(stderr) end
            if item.show_osd and item.output == M.output() and state.available then
                awesome.emit_signal(item.kind == 'sink' and 'module::volume_osd:show' or 'module::mic_osd:show', true)
            end
            if #queue > 0 then timer:again() end
        end)
end
timer = gears.timer { timeout = 0.08, single_shot = true, callback = apply_next }

local function enqueue(output, kind, action, value, show_osd)
    local last = queue[#queue]
    if last and last.output == output and last.kind == kind and last.action == action and action ~= 'mute' then
        last.value = action == 'adjust' and (last.value + value) or value
        last.show_osd = last.show_osd or show_osd
    else
        queue[#queue + 1] = { output = output, kind = kind, action = action, value = value, show_osd = show_osd }
    end
    if not active then timer:again() end
end

function M.set(output, value) enqueue(output, 'sink', 'set', value, true) end

function M.adjust(delta) enqueue(M.output(), 'sink', 'adjust', delta, true) end

function M.toggle(kind) enqueue(M.output(), kind, 'mute', nil, true) end

return M
