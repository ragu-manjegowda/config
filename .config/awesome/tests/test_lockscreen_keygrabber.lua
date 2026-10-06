-- Model Awesome's stop(nil) semantics: an inactive object's stop can remove
-- another object's callback without clearing that owner's grabber field.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local lifecycle = require('module.lockscreen-lifecycle')

local function fixture()
    local api, actions = {}, {}
    local locked, authenticated = true, false
    local function make(name)
        local object = { starts = 0, stops = 0 }
        function object:start()
            if self.grabber or api.current_instance then return false end
            self.grabber = function() authenticated = true end
            api.callback, api.current_instance = self.grabber, self
            self.starts = self.starts + 1
            actions[#actions + 1] = 'start:' .. name
        end

        function object:stop()
            local callback = self.grabber or (api.current_instance and api.current_instance.grabber)
            if callback and callback == api.callback then
                api.callback, api.current_instance = nil, nil
            end
            self.grabber = nil
            self.stops = self.stops + 1
            actions[#actions + 1] = 'stop:' .. name
        end

        return object
    end
    return api, make, actions, function() assert(locked and not authenticated) end
end

do
    local api, make, actions, unchanged_auth = fixture()
    local password = make('password')
    assert(lifecycle.ensure_keygrab(api, password))
    local callback = password.grabber
    assert(api.callback == callback and password.starts == 1)
    assert(lifecycle.ensure_keygrab(api, password))
    assert(password.grabber == callback and #actions == 1,
        'Repeated lock requests must preserve the existing password grab')
    unchanged_auth()
end

do
    local api, make, actions, unchanged_auth = fixture()
    local calendar, password = make('calendar'), make('password')
    calendar:start()
    assert(lifecycle.ensure_keygrab(api, password))
    assert(table.concat(actions, ',') == 'start:calendar,stop:calendar,start:password',
        'Locking must stop the prior prompt before taking password input')
    assert(calendar.grabber == nil and api.callback == password.grabber)
    unchanged_auth()
end

do
    local api, make, actions, unchanged_auth = fixture()
    local password, inactive_calendar = make('password'), make('calendar')
    password:start()
    inactive_calendar:stop() -- Reproduce the bug in the old calendar lock hook.
    assert(api.current_instance == nil and api.callback == nil and password.grabber,
        'The fixture must reproduce an orphaned password transaction')
    assert(password:start() == false, 'Awesome refuses to restart the stale object')
    assert(lifecycle.ensure_keygrab(api, password), 'A repeated lock request must recover password input')
    assert(password.starts == 2 and password.stops == 1 and api.callback == password.grabber)
    assert(table.concat(actions, ',') == 'start:password,stop:calendar,stop:password,start:password')
    unchanged_auth()
end

do
    local api, make, actions, unchanged_auth = fixture()
    local password, foreign = make('password'), make('foreign')
    password:start()
    make('inactive'):stop()
    foreign:start()
    assert(lifecycle.ensure_keygrab(api, password))
    assert(actions[#actions - 2] == 'stop:foreign' and actions[#actions - 1] == 'stop:password'
        and actions[#actions] == 'start:password', 'Both foreign and stale transactions must be retired')
    assert(api.current_instance == password)
    unchanged_auth()
end

do
    local api, make, _, unchanged_auth = fixture()
    local password = make('password')
    local start = password.start
    function password:start() return false end

    assert(not lifecycle.ensure_keygrab(api, password), 'A failed acquisition must not report success')
    password.start = start
    assert(lifecycle.ensure_keygrab(api, password), 'The next lock retry must acquire input')
    unchanged_auth()
end

print('lockscreen password ownership, stale-grab recovery and acquisition retry tests passed')
