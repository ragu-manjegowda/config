local Gio = require('lgi').Gio
local M = {}

local function read_line(path)
    local file = io.open(path, 'r')
    if not file then return nil end
    local line = file:read('*l')
    file:close()
    return line
end

function M.read(hwmon_dir)
    local directory = hwmon_dir or '/sys/class/hwmon'
    local ok, enumerator = pcall(function()
        return Gio.File.new_for_path(directory):enumerate_children(
            'standard::name', Gio.FileQueryInfoFlags.NONE
        )
    end)
    if not ok or not enumerator then return nil end

    local temperature
    for info in function() return enumerator:next_file() end do
        local name = info:get_name()
        if name:match('^hwmon%d+$') then
            local device = directory .. '/' .. name
            if read_line(device .. '/name') == 'coretemp' and
                read_line(device .. '/temp1_label') == 'Package id 0' then
                local millidegrees = tonumber(read_line(device .. '/temp1_input'))
                if millidegrees and millidegrees >= 0 then
                    temperature = millidegrees / 1000
                end
                break
            end
        end
    end
    enumerator:close()
    return temperature
end

return M
