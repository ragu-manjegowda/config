local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

local clients = {}

local function make_tags(count)
    local tags = {}
    for index = 1, count do
        local tag = { index = index, name = tostring(index), selected = index == 1 }
        function tag:clients()
            local result = {}
            for _, client in ipairs(clients) do
                for _, assigned in ipairs(client._tags) do
                    if assigned == self then
                        result[#result + 1] = client
                    end
                end
            end
            return result
        end
        function tag:view_only()
            self.selected = true
        end
        tags[index] = tag
    end
    return tags
end

local primary = {
    valid = true,
    outputs = { ["eDP-1"] = true },
    geometry = { x = 0, y = 0, width = 2880, height = 1800 },
    tags = make_tags(9)
}
local external = {
    valid = true,
    outputs = { ["DP-4"] = true },
    geometry = { x = 2880, y = 0, width = 2880, height = 1620 },
    tags = make_tags(9)
}

local function make_client(tags, geometry)
    local client = {
        valid = true,
        _tags = tags,
        _geometry = geometry,
        screen = primary,
        floating = true,
        maximized = false,
        fullscreen = false,
        minimized = false
    }
    function client:tags(value)
        if value then
            self._tags = value
        end
        return self._tags
    end
    function client:geometry(value)
        if value then
            self._geometry = value
        end
        return self._geometry
    end
    function client:move_to_screen(target)
        if self.fail_move then
            error("move failed")
        end
        self.screen = target
    end
    clients[#clients + 1] = client
    return client
end

local multi_tag = make_client(
    { primary.tags[1], primary.tags[3] },
    { x = 100, y = 50, width = 800, height = 600 })
local single_tag = make_client(
    { primary.tags[2] },
    { x = 200, y = 100, width = 900, height = 700 })

local screens = { primary, external }
local screen_signals = {}
local pending_timers = {}
_G.screen = setmetatable({ primary = primary }, {
    __call = function(_, _, previous)
        if previous == nil then
            return screens[1]
        end
        for index, value in ipairs(screens) do
            if value == previous then
                return screens[index + 1]
            end
        end
    end
})
function screen.connect_signal(name, handler)
    screen_signals[name] = handler
end

_G.awesome = { startup = false }
package.loaded.awful = {
    client = { iterate = function() return function() return nil end end },
    layout = { arrange = function() end },
    screen = { focus = function() end }
}
package.loaded.gears = {
    timer = {
        start_new = function(_, callback)
            pending_timers[#pending_timers + 1] = callback
        end
    }
}
package.loaded.naughty = { notification = function() end }
package.loaded["configuration.config"] = {
    display = {
        primary = { name = "eDP-1" },
        external = { name = "DP-4" }
    }
}

local manager = require("module.screen-manager")
manager.migrate_to_external()

assert(multi_tag.screen == external and single_tag.screen == external,
    "fresh connection must move every primary client")
assert(#multi_tag:tags() == 2 and multi_tag:tags()[1] == external.tags[1] and
    multi_tag:tags()[2] == external.tags[3],
    "fresh connection must preserve all client tags")
assert(multi_tag:geometry().x == 2980 and multi_tag:geometry().y == 50,
    "fresh connection must preserve screen-relative floating geometry")

manager.prepare_for_disconnect()
assert(multi_tag.screen == primary and single_tag.screen == primary,
    "disconnect preparation must move every external client")
assert(#multi_tag:tags() == 2 and multi_tag:tags()[1] == primary.tags[1] and
    multi_tag:tags()[2] == primary.tags[3],
    "disconnect preparation must preserve all client tags")
assert(multi_tag:geometry().x == 100 and multi_tag:geometry().y == 50,
    "disconnect preparation must restore relative floating geometry")

screen_signals.added(external)
assert(#pending_timers == 1, "reconnect must schedule one deferred restore")
manager.prepare_for_disconnect()
for _, callback in ipairs(pending_timers) do
    callback()
end
pending_timers = {}
assert(multi_tag.screen == primary and single_tag.screen == primary,
    "stale reconnect timers must not restore clients after a new disconnect starts")

single_tag.fail_move = true
local success = pcall(manager.migrate_to_external)
assert(not success, "per-client migration failures must propagate to the caller")
assert(multi_tag.screen == primary and multi_tag:tags()[1] == primary.tags[1] and
    multi_tag:tags()[2] == primary.tags[3],
    "partial fresh migration must roll successfully moved clients back")

single_tag.fail_move = false
manager.migrate_to_external()
single_tag.fail_move = true
success = pcall(manager.prepare_for_disconnect)
assert(not success, "partial disconnect migration failures must propagate")
assert(multi_tag.screen == external and multi_tag:tags()[1] == external.tags[1] and
    multi_tag:tags()[2] == external.tags[3],
    "partial disconnect migration must restore successfully moved clients")

screens = { external }
screen.primary = external
single_tag.fail_move = false
success = pcall(manager.prepare_for_disconnect)
assert(not success, "disconnect must fail when the configured primary screen is unavailable")
assert(multi_tag.screen == external and single_tag.screen == external,
    "external-only disconnect failure must leave clients on the active screen")

print("Screen manager tests passed")
