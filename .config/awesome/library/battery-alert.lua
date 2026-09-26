-- Emit one warning per distinct UPower update, even with multiple widget callbacks.
local battery_alert = {}

function battery_alert.new()
    local last_low_update
    local handled_critical = false

    return function(percentage, status, update_time)
        if status == 'charging' or status == 'fully-charged' or
            status == 'pending-charge' or status == 'not charging' then
            last_low_update = nil
            handled_critical = false
            return nil
        end

        if status ~= 'discharging' or type(percentage) ~= 'number' then
            return nil
        end

        if percentage <= 5 and not handled_critical then
            handled_critical = true
            return 'critical'
        end

        if percentage > 5 and percentage < 20 then
            -- UPower's notify signal fires for each changed property in a
            -- single sample; all of those callbacks share its update time.
            local stamp = tonumber(update_time)
            if not stamp or stamp <= 0 then
                stamp = os.time()
            end
            if stamp == last_low_update then
                return nil
            end
            last_low_update = stamp
            return 'low'
        end

        return nil
    end
end

return battery_alert
