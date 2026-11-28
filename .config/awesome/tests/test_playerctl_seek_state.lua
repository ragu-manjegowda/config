#!/usr/bin/env lua

local emitted_positions = {}
local emitted_metadata
local fake_player = {
    player_name = 'test',
    playback_status = 'PAUSED',
    position = 100000000,
    metadata = { value = { ['mpris:length'] = 1000000000 } },
}

function fake_player:get_title()
    return 'Rock <Live>'
end

function fake_player:get_artist()
    return 'Hall & Oates'
end

function fake_player:get_album()
    return '"Greatest Hits"'
end

function fake_player:print_metadata_prop()
    return ''
end

function fake_player:get_position()
    return self.position
end

function fake_player:set_position(position)
    self.position = position
end

function fake_player:play_pause() end

function fake_player:previous() end

function fake_player:next() end

local manager = {
    player_names = { { name = 'test' } },
    players = {},
}

function manager:manage_player(player)
    self.players = { player }
end

function manager:move_player_to_top(player)
    self.players = { player }
end

local timer = {
    delayed_call = function(callback)
        callback()
    end,
}

setmetatable(timer, {
    __call = function(_, args)
        args.started = false
        function args:start()
            self.started = true
        end

        function args:stop()
            self.started = false
        end

        return args
    end,
})

package.loaded.awful = {
    spawn = {
        easy_async = function()
            error('artwork download was not expected')
        end,
    },
}

package.loaded.gears = {
    object = function()
        return {
            emit_signal = function(_, signal, first, second, artwork, album)
                if signal == 'position' then
                    emitted_positions[#emitted_positions + 1] = { first, second }
                elseif signal == 'metadata' then
                    emitted_metadata = { first, second, album }
                end
            end,
        }
    end,
    timer = timer,
}

package.loaded.lgi = {
    Gio = {
        File = {
            new_for_uri = function()
                return { get_path = function() return nil end }
            end,
        },
    },
    Playerctl = {
        PlayerManager = function()
            return manager
        end,
        Player = {
            new_from_name = function()
                return fake_player
            end,
        },
    },
}

local service = dofile(os.getenv('HOME') .. '/.config/awesome/library/playerctl.lua')
assert(emitted_metadata[1] == 'Rock <Live>' and emitted_metadata[2] == 'Hall & Oates'
    and emitted_metadata[3] == '"Greatest Hits"', 'Metadata must be plain text, not Pango markup')
service:set_position(400)

fake_player.position = 0
fake_player.metadata.value['mpris:length'] = nil
fake_player.on_metadata(fake_player, fake_player.metadata)

local latest = emitted_positions[#emitted_positions]
assert(latest[1] == 400, 'paused seek reset position to ' .. tostring(latest[1]))
assert(latest[2] == 1000, 'paused seek reset length to ' .. tostring(latest[2]))

print('Playerctl paused seek state test passed')
