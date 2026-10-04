-- Test-only filesystem/OS replacements keep real workspace state untouched.
-- luacheck: ignore 122
local home = assert(os.getenv('HOME'))
local original_getenv, original_open = os.getenv, io.open
local original_remove, original_rename = os.remove, os.rename
local state_file = home .. '/fixture-state/awesome/last-workspace'
local legacy_file = home .. '/.config/awesome/utilities/awesome-last-ws'
local files, warnings = {}, {}
local fail_write, fail_rename = false, false

os.getenv = function(name)
    if name == 'XDG_STATE_HOME' then return home .. '/fixture-state' end
    return original_getenv(name)
end
io.open = function(path, mode)
    if mode == 'w' then
        if fail_write then return nil, 'permission denied' end
        files[path] = ''
        return {
            write = function(self, ...)
                files[path] = table.concat({ ... }); return self
            end,
            close = function() return true end,
        }
    end
    if files[path] == nil then return nil end
    return {
        read = function() return files[path]:match('([^\n]+)') end,
        close = function() return true end,
    }
end
os.remove = function(path)
    files[path] = nil; return true
end
os.rename = function(source, destination)
    if fail_rename then return nil, 'rename failed' end
    files[destination], files[source] = files[source], nil
    return true
end
package.loaded['gears.filesystem'] = {
    get_configuration_dir = function() return home .. '/.config/awesome/' end,
    make_directories = function(path) assert(path == home .. '/fixture-state/awesome/') end,
}
package.loaded['gears.debug'] = {
    print_warning = function(message) warnings[#warnings + 1] = message end,
}
local state = dofile(home .. '/.config/awesome/library/workspace-state.lua')

assert(state.load() == nil, 'missing state must preserve default workspace selection')
files[legacy_file] = '7|2\n'
assert(state.load() == '7|2' and files[state_file] == '7|2\n' and files[legacy_file] == nil,
    'legacy workspace was not migrated before retiring its old file')
files[legacy_file] = '2|1\n'
assert(state.load() == '7|2', 'legacy state overrode newer XDG state')
assert(state.save('4|1') and files[state_file] == '4|1\n')
fail_rename = true
assert(not state.save('9|2') and files[state_file] == '4|1\n',
    'failed atomic replacement destroyed the previous state')
assert(files[state_file .. '.tmp'] == nil, 'failed save left a temporary file')
fail_rename = false
files[state_file] = nil
fail_write = true
assert(state.load() == '2|1' and files[legacy_file] == '2|1\n',
    'failed migration discarded recoverable legacy data')
assert(#warnings == 2, 'write failures must be reported without breaking Awesome exit')

os.getenv, io.open = original_getenv, original_open
os.remove, os.rename = original_remove, original_rename
print('workspace state migration tests passed')
