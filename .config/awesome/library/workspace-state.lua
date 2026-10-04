local filesystem = require('gears.filesystem')
local debug = require('gears.debug')
local M = {}

local state_dir = (os.getenv('XDG_STATE_HOME') or (os.getenv('HOME') .. '/.local/state')) .. '/awesome/'
local state_file = state_dir .. 'last-workspace'
local legacy_file = filesystem.get_configuration_dir() .. 'utilities/awesome-last-ws'

function M.save(line)
    local temporary = state_file .. '.tmp'
    local file
    local ok, err = pcall(function()
        filesystem.make_directories(state_dir)
        file = assert(io.open(temporary, 'w'))
        assert(file:write(line, '\n'))
        assert(file:close())
        file = nil
        assert(os.rename(temporary, state_file))
    end)
    if not ok then
        if file then pcall(file.close, file) end
        os.remove(temporary)
        debug.print_warning('Unable to save workspace state: ' .. tostring(err))
    end
    return ok
end

function M.load()
    local file = io.open(state_file, 'r')
    local migrating = not file
    if not file then file = io.open(legacy_file, 'r') end
    if not file then return nil end
    local line = file:read('*line')
    file:close()
    -- The previous Awesome instance may write this legacy file during restart.
    -- Retire it only after its contents have been preserved successfully.
    if migrating and line and M.save(line) then os.remove(legacy_file) end
    return line
end

return M
