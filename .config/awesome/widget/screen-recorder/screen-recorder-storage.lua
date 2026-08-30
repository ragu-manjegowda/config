local lgi = require('lgi')
local filesystem = require('gears.filesystem')

local Gio = lgi.Gio
local storage = {}

function storage.read(path, limit)
    local file = Gio.File.new_for_path(path)
    local success, info = pcall(
        file.query_info,
        file,
        'standard::type,standard::size,id::file',
        Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS)
    if not success or not info then return nil end
    if tostring(info:get_file_type()) ~= 'REGULAR' or info:get_size() > limit then
        return nil
    end
    local open_success, stream = pcall(file.read, file)
    if not open_success or not stream then return nil end
    local info_success, stream_info = pcall(
        stream.query_info, stream, 'standard::type,standard::size,id::file')
    local path_id = info:get_attribute_string('id::file')
    local stream_id = stream_info and stream_info:get_attribute_string('id::file')
    if not info_success or not stream_info or
        tostring(stream_info:get_file_type()) ~= 'REGULAR' or
        not path_id or path_id ~= stream_id or
        stream_info:get_size() > limit then
        stream:close()
        return nil
    end
    local read_success, bytes = pcall(stream.read_bytes, stream, limit + 1)
    stream:close()
    if not read_success or not bytes then return nil end
    local content = bytes:get_data()
    if #content > limit then return nil end
    return content
end

function storage.write(path, content)
    filesystem.make_parent_directories(path)
    local file = Gio.File.new_for_path(path)
    local flags = Gio.FileCreateFlags.PRIVATE + Gio.FileCreateFlags.REPLACE_DESTINATION
    local success, err = pcall(file.replace_contents, file, content, nil, false, flags)
    if not success then error(err) end
end

function storage.remove(path)
    local file = Gio.File.new_for_path(path)
    pcall(file.delete, file)
end

return storage
