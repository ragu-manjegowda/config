local storage = require('widget.screen-recorder.screen-recorder-storage')

local recorder_state = {}
local valid_sources = {
    primary = true,
    external = true,
    both = true,
    region = true
}
local MAX_GEOMETRY_VALUE = 1048576

local function parse_size(value)
    local width, height = tostring(value):match('^(%d+)x(%d+)$')
    return tonumber(width), tonumber(height)
end

local function parse_position(value)
    local x, y = tostring(value):match('^(%-?%d+)x(%-?%d+)$')
    return tonumber(x), tonumber(y)
end

local function display_geometry(display)
    local width, height = parse_size(display.scale_from or display.mode)
    local x, y = parse_position(display.position)
    if not width or not height or not x or not y then
        return nil
    end
    return { x = x, y = y, width = width, height = height }
end

local function copy_region(region)
    return {
        x = region.x,
        y = region.y,
        width = region.width,
        height = region.height
    }
end

local function normalized_geometry(geometry, root_width, root_height)
    if geometry.x > MAX_GEOMETRY_VALUE or geometry.y > MAX_GEOMETRY_VALUE or
        geometry.width > MAX_GEOMETRY_VALUE or geometry.height > MAX_GEOMETRY_VALUE then
        return nil
    end
    geometry.width = geometry.width - (geometry.width % 2)
    geometry.height = geometry.height - (geometry.height % 2)
    if geometry.x < 0 or geometry.y < 0 or geometry.width < 16 or geometry.height < 16 or
        (root_width and root_height and
            (geometry.x + geometry.width > root_width or
                geometry.y + geometry.height > root_height)) then
        return nil
    end
    return geometry
end

function recorder_state.path()
    local home = assert(os.getenv('HOME'))
    local state_home = os.getenv('XDG_STATE_HOME')
    if not state_home or state_home == '' then state_home = home .. '/.local/state' end
    return state_home .. '/awesome/screen-recorder/settings'
end

function recorder_state.default(source, audio)
    return {
        source = valid_sources[source] and source or 'primary',
        region = nil,
        audio = audio == true
    }
end

function recorder_state.parse_selection(value, root_width, root_height)
    local x, y, width, height = tostring(value):match(
        '^%s*(%-?%d+)%s+(%-?%d+)%s+(%d+)%s+(%d+)%s*$')
    x, y, width, height = tonumber(x), tonumber(y), tonumber(width), tonumber(height)
    if not x or not y or not width or not height or x < 0 or y < 0 or
        x > MAX_GEOMETRY_VALUE or y > MAX_GEOMETRY_VALUE or
        width > MAX_GEOMETRY_VALUE or height > MAX_GEOMETRY_VALUE or
        width < 16 or height < 16 then
        return nil
    end
    width = width - (width % 2)
    height = height - (height % 2)
    if root_width and root_height and
        (x + width > root_width or y + height > root_height) then
        return nil
    end
    return { x = x, y = y, width = width, height = height }
end

function recorder_state.resolve(state, primary, external, external_connected, root_width, root_height)
    if state.source == 'region' then
        if state.region and recorder_state.parse_selection(string.format(
            '%d %d %d %d', state.region.x, state.region.y,
            state.region.width, state.region.height), root_width, root_height) then
            return copy_region(state.region)
        end
        return nil, 'Saved area is outside the current desktop'
    end

    if not external_connected then
        if state.source == 'external' or state.source == 'both' then
            return nil, 'External display unavailable'
        end
    end

    local external_geometry
    if state.source == 'external' or state.source == 'both' then
        external_geometry = display_geometry(external)
        if not external_geometry then
            return nil, 'External display geometry is invalid'
        end
        external_geometry = normalized_geometry(external_geometry, root_width, root_height)
        if not external_geometry then
            return nil, 'External display geometry is outside the current desktop'
        end
    end
    if state.source == 'external' then return external_geometry end

    local primary_geometry = display_geometry(primary)
    if not primary_geometry then
        return nil, 'Primary display geometry is invalid'
    end
    primary_geometry = normalized_geometry(primary_geometry, root_width, root_height)
    if not primary_geometry then
        return nil, 'Primary display geometry is outside the current desktop'
    end
    if state.source == 'primary' then return primary_geometry end

    local min_x = math.min(primary_geometry.x, external_geometry.x)
    local min_y = math.min(primary_geometry.y, external_geometry.y)
    local max_x = math.max(
        primary_geometry.x + primary_geometry.width,
        external_geometry.x + external_geometry.width)
    local max_y = math.max(
        primary_geometry.y + primary_geometry.height,
        external_geometry.y + external_geometry.height)
    local both_geometry = {
        x = min_x,
        y = min_y,
        width = max_x - min_x,
        height = max_y - min_y
    }
    return normalized_geometry(both_geometry, root_width, root_height)
end

function recorder_state.load(path, default_source, default_audio)
    local state = recorder_state.default(default_source, default_audio)
    local content = storage.read(path, 4096)
    if not content then return state end

    local source = content:match('source=([%a]+)')
    if valid_sources[source] then
        state.source = source
    end
    local audio = content:match('audio=(%a+)')
    if audio == 'true' then
        state.audio = true
    elseif audio == 'false' then
        state.audio = false
    end
    local x, y, width, height = content:match(
        'region=(%-?%d+),(%-?%d+),(%d+),(%d+)')
    if x then
        state.region = recorder_state.parse_selection(
            table.concat({ x, y, width, height }, ' '))
    end
    if state.source == 'region' and not state.region then
        state.source = valid_sources[default_source] and default_source or 'primary'
    end
    return state
end

function recorder_state.save(path, state)
    assert(valid_sources[state.source])
    local content = 'source=' .. state.source .. '\n' ..
        'audio=' .. tostring(state.audio == true) .. '\n'
    if state.region then
        content = content .. string.format(
            'region=%d,%d,%d,%d\n',
            state.region.x, state.region.y, state.region.width, state.region.height)
    end
    storage.write(path, content)
end

function recorder_state.ffmpeg_geometry(region)
    assert(region.x >= 0 and region.y >= 0)
    return string.format('%dx%d', region.width, region.height),
        string.format(':0.0+%d,%d', region.x, region.y)
end

function recorder_state.summary(region)
    return string.format(
        '%dx%d at %d,%d', region.width, region.height, region.x, region.y)
end

return recorder_state
