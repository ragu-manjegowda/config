local naughty = require('naughty')

local suspension = {
    reasons = {},
}

function suspension.set(reason, enabled)
    suspension.reasons[reason] = enabled and true or nil
    naughty.suspended = next(suspension.reasons) ~= nil
end

function suspension.is_active(reason)
    return suspension.reasons[reason] == true
end

return suspension
