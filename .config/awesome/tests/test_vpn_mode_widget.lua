local home = assert(os.getenv('HOME'))
local signals = {}
local status_callback
local watches = {}
local timers = {}
local imagebox
local tooltip

local function widget(attributes)
    if attributes.widget == 'imagebox' then imagebox = attributes end
    return attributes
end
package.loaded.awful = {
    widget = { watch = function(_, _, callback)
        status_callback = callback
        return {}, { again = function() end }
    end },
    spawn = {
        easy_async = function(argv, callback)
            watches[#watches + 1] = { argv = argv, callback = callback }
        end,
    },
    tooltip = function(attributes)
        tooltip = attributes
        function attributes:set_text(value) self.text = value end
        return attributes
    end,
}
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return home .. '/.config/awesome/' end },
    timer = function(attributes)
        function attributes:again() self.running = true end
        function attributes:stop() self.running = false end
        timers[#timers + 1] = attributes
        return attributes
    end,
}
package.loaded.wibox = {
    widget = setmetatable({ imagebox = 'imagebox' }, { __call = function(_, value) return widget(value) end }),
    container = { margin = 'margin' },
}
package.loaded.beautiful = { xresources = { apply_dpi = function(value) return value end } }
package.loaded.naughty = { notification = function() end }
awesome = {
    connect_signal = function(name, callback) signals[name] = callback end,
    emit_signal = function(name, ...)
        if signals[name] then signals[name](...) end
    end,
}

local make_button = dofile(home .. '/.config/awesome/widget/vpn/init.lua')
local button = make_button()
local function status(value) status_callback(nil, value .. '\n') end
local icons = home .. '/.config/awesome/widget/vpn/icons/'
assert(not button.visible)
assert(#timers == 1, 'VPN should not retain a disconnected-icon hide timer')

status('connecting namespace')
assert(button.visible and tooltip.text == 'VPN connecting (namespace: opt-in SSH/browser)',
    'initial connection was mislabeled as a reconnect')
assert(imagebox.image == icons .. 'prisma-access-namespace-connecting.svg',
    'connecting namespace should show both N and exclamation badges')
status('connecting namespace')
assert(button.visible and imagebox.image == icons .. 'prisma-access-namespace-connecting.svg',
    'connecting indicator must persist while Prisma continues reporting Connecting')
status('connected namespace')
assert(button.visible and imagebox.image == icons .. 'prisma-access-namespace.svg')
assert(tooltip.text == 'VPN connected (namespace: opt-in SSH/browser)')
assert(#watches == 0, 'namespace mode launched a host connectivity check')
status('disconnected namespace')
assert(not button.visible, 'a disconnected tunnel should hide without a grace period')
status('connecting namespace')
assert(button.visible and tooltip.text == 'VPN connecting (namespace: opt-in SSH/browser)',
    'connecting after a disconnected state should be treated as a new connection')
assert(imagebox.image == icons .. 'prisma-access-namespace-connecting.svg')
status('connected namespace')
status('connecting namespace')
assert(tooltip.text == 'VPN reconnecting (namespace: opt-in SSH/browser)',
    'a live tunnel entering Connecting was not identified as reconnecting')
assert(button.visible and imagebox.image == icons .. 'prisma-access-namespace-connecting.svg')
status('connected namespace')

status('connected global')
assert(imagebox.image == icons .. 'prisma-access.svg')
assert(tooltip.text == 'VPN connected (host-wide)')
assert(#watches == 1, 'global mode did not launch a host connectivity check')
watches[1].callback('', '', '', 1)
assert(tooltip.text == 'VPN connected (host-wide) · degraded')
status('connecting global')
assert(button.visible and imagebox.image == icons .. 'prisma-access-connecting.svg')
assert(tooltip.text == 'VPN reconnecting (host-wide)')
status('connecting global')
assert(button.visible and imagebox.image == icons .. 'prisma-access-connecting.svg',
    'host-wide connecting indicator must not expire before the state changes')
status('connected global')
assert(imagebox.image == icons .. 'prisma-access.svg')
status('connected namespace')
assert(imagebox.image == icons .. 'prisma-access-namespace.svg')
assert(tooltip.text == 'VPN connected (namespace: opt-in SSH/browser)')

status('disconnected')
assert(not button.visible and tooltip.text == 'VPN disconnected',
    'stopping the namespace service should hide its icon immediately')
status('connecting namespace')
assert(tooltip.text == 'VPN connecting (namespace: opt-in SSH/browser)',
    'starting the service again after manual disconnect was mislabeled as a reconnect')
status('disconnected')
status('connecting global')
assert(tooltip.text == 'VPN connecting (host-wide)',
    'switching modes was mislabeled as a reconnect')
assert(imagebox.image == icons .. 'prisma-access-connecting.svg')
status('disconnected')
status('connecting namespace')
assert(tooltip.text == 'VPN connecting (namespace: opt-in SSH/browser)',
    'a stopped service should clear reconnection history')
status('disconnected')

status('connected global')
status('connecting global')
assert(tooltip.text == 'VPN reconnecting (host-wide)',
    'host-wide tunnel recovery was not distinguished from an initial connection')
status('disconnected')
assert(not button.visible and tooltip.text == 'VPN disconnected',
    'stopping the host service should hide its icon immediately')
print('VPN mode widget tests passed')
