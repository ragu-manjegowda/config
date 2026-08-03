local awful = require('awful')
local gears = require('gears')
local Gio = require('lgi').Gio
local Playerctl = require('lgi').Playerctl

local service = gears.object {}
local manager
local active_player
local artwork_path
local artwork_generation = 0
local last_metadata
local last_position = 0
local last_length = 0

local function active()
    return manager and manager.players[1] or nil
end

local function remove_downloaded_artwork()
    if artwork_path then
        os.remove(artwork_path)
        artwork_path = nil
    end
end

local function emit_metadata(title, artist, art_url, album, player_name)
    artwork_generation = artwork_generation + 1
    local generation = artwork_generation

    title = gears.string.xml_escape(title or '')
    artist = gears.string.xml_escape(artist or '')
    album = gears.string.xml_escape(album or '')
    art_url = art_url or ''

    if player_name == 'spotify' then
        art_url = art_url:gsub('open.spotify.com', 'i.scdn.co')
    end

    local local_art
    if art_url ~= '' then
        local ok, path = pcall(function()
            return Gio.File.new_for_uri(art_url):get_path()
        end)
        local_art = ok and path or nil
    end
    if local_art then
        remove_downloaded_artwork()
        service:emit_signal('metadata', title, artist, local_art, album, player_name)
        return
    end

    if not art_url:match('^https?://') then
        remove_downloaded_artwork()
        service:emit_signal('metadata', title, artist, '', album, player_name)
        return
    end

    local destination = os.tmpname()
    awful.spawn.easy_async({
        'curl',
        '--fail',
        '--location',
        '--silent',
        '--show-error',
        '--connect-timeout', '3',
        '--max-time', '10',
        '--max-filesize', '10485760',
        '--proto', '=http,https',
        '--output', destination,
        art_url,
    }, function(_, _, _, exit_code)
        if generation ~= artwork_generation or exit_code ~= 0 then
            os.remove(destination)
            if generation == artwork_generation then
                service:emit_signal('metadata', title, artist, '', album, player_name)
            end
            return
        end

        remove_downloaded_artwork()
        artwork_path = destination
        service:emit_signal('metadata', title, artist, artwork_path, album, player_name)
    end)
end

local function publish_metadata(player)
    if player ~= active() then
        return
    end

    local ok, title, artist, album, art_url = pcall(function()
        return player:get_title() or '',
            player:get_artist() or '',
            player:get_album() or '',
            player:print_metadata_prop('mpris:artUrl') or ''
    end)
    if not ok then
        return
    end
    local metadata_key = table.concat({ player.player_name, title, artist, album, art_url }, '\0')

    if metadata_key == last_metadata then
        return
    end

    last_metadata = metadata_key
    emit_metadata(title, artist, art_url, album, player.player_name)
end

local function update_position()
    local player = active()
    if not player then
        return
    end

    local ok, position = pcall(function()
        return player:get_position()
    end)
    if not ok then
        return
    end

    local metadata = player.metadata and player.metadata.value or {}
    local position_sec = position / 1000000
    local length_sec = (tonumber(metadata['mpris:length']) or 0) / 1000000

    if length_sec > 0 then
        last_length = length_sec
    end
    if position_sec > 0 or length_sec > 0 or last_position == 0 then
        last_position = position_sec
    end

    if last_length > 0 then
        service:emit_signal('position', last_position, last_length, player.player_name)
    end
end

local position_timer = gears.timer {
    timeout = 1,
    callback = update_position,
}

local function publish_status(player)
    if player ~= active() then
        return
    end

    if player ~= active_player then
        last_metadata = nil
        last_position = 0
        last_length = 0
    end
    active_player = player
    local playing = tostring(player.playback_status):upper():find('PLAYING', 1, true) ~= nil
    service:emit_signal('playback_status', playing, player.player_name)
    update_position()

    if playing then
        position_timer:start()
    else
        position_timer:stop()
    end
end

local function publish_current_player()
    local player = active()
    if not player then
        active_player = nil
        last_metadata = nil
        last_position = 0
        last_length = 0
        artwork_generation = artwork_generation + 1
        position_timer:stop()
        remove_downloaded_artwork()
        service:emit_signal('no_players')
        return
    end

    active_player = player
    publish_metadata(player)
    publish_status(player)
end

local function make_active(player)
    if manager and player ~= active() then
        manager:move_player_to_top(player)
        last_metadata = nil
        last_position = 0
        last_length = 0
    end
end

local function manage_player(name)
    local player = Playerctl.Player.new_from_name(name)
    manager:manage_player(player)

    player.on_metadata = function(current)
        make_active(current)
        publish_metadata(current)
        update_position()
    end
    player.on_playback_status = function(current)
        make_active(current)
        publish_status(current)
    end
    player.on_seeked = function(current)
        if current == active() then
            update_position()
        end
    end
    player.on_exit = function()
        gears.timer.delayed_call(publish_current_player)
    end

    return player
end

local function start_manager()
    manager = Playerctl.PlayerManager()

    function manager:on_name_appeared(name)
        manage_player(name)
        publish_current_player()
    end

    function manager:on_player_vanished(player)
        if player == active_player or #self.players == 0 then
            last_metadata = nil
            publish_current_player()
        end
    end

    for _, name in ipairs(manager.player_names) do
        manage_player(name)
    end

    publish_current_player()
end

local function call_active(method, value)
    local player = active()
    if not player then
        return
    end

    pcall(function()
        if value == nil then
            player[method](player)
        else
            player[method](player, value)
        end
    end)
end

function service:play_pause()
    call_active('play_pause')
end

function service:previous()
    call_active('previous')
end

function service:next()
    call_active('next')
end

function service:set_position(position)
    last_position = position
    call_active('set_position', position * 1000000)
    update_position()
end

gears.timer.delayed_call(function()
    local ok, err = pcall(start_manager)
    if not ok then
        io.stderr:write('[Playerctl] ' .. tostring(err) .. '\n')
        service:emit_signal('no_players')
    end
end)

return service
