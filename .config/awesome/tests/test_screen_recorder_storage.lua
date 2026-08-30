local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" ..
    "/usr/share/awesome/lib/?.lua;/usr/share/awesome/lib/?/init.lua;" .. package.path

local lgi = require("lgi")
local Gio, GLib = lgi.Gio, lgi.GLib
package.loaded["gears.filesystem"] = {
    make_parent_directories = function(path)
        assert(GLib.mkdir_with_parents(assert(path:match("^(.+)/[^/]+$")), tonumber("700", 8)) == 0)
    end
}
local storage = require("widget.screen-recorder.screen-recorder-storage")
local directory = assert(GLib.dir_make_tmp("screen-recorder-storage-XXXXXX"))
local settings = directory .. "/settings"
assert(storage.read(settings, 4096) == nil, "missing state must load as absent")

storage.write(settings, "source=primary\n")
assert(storage.read(settings, 4096) == "source=primary\n",
    "private state must round-trip")
local mode_info = Gio.File.new_for_path(settings):query_info(
    "unix::mode", Gio.FileQueryInfoFlags.NONE)
assert(mode_info:get_attribute_uint32("unix::mode") % 512 == 384,
    "published state must be mode 0600")

local victim = directory .. "/victim"
local link = directory .. "/link"
assert(GLib.file_set_contents(victim, "unchanged"))
assert(Gio.File.new_for_path(link):make_symbolic_link(victim))
assert(storage.read(link, 4096) == nil, "state reads must reject symbolic links")
storage.write(link, "replacement")
assert(GLib.file_get_contents(victim) == "unchanged",
    "atomic state replacement must not follow a destination symlink")
assert(storage.read(link, 4096) == "replacement",
    "state replacement must produce a regular file")

assert(GLib.file_set_contents(settings, string.rep("x", 4097)))
assert(storage.read(settings, 4096) == nil, "oversized state must be rejected")

os.remove(link)
os.remove(victim)
os.remove(settings)
assert(GLib.rmdir(directory) == 0)
print("Screen recorder storage tests passed")
