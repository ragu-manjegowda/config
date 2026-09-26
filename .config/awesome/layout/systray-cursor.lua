-- The XEmbed tray owns an X window distinct from the enclosing wibar.
local systray_cursor = {}

local has_ffi, ffi = pcall(require, 'ffi')
if not has_ffi then
    -- Awesome's plain-Lua test runtime cannot call Xlib.
    function systray_cursor.apply() return true end
    return systray_cursor
end

ffi.cdef [[
    typedef struct _XDisplay Display;
    typedef unsigned long XID;
    Display *XOpenDisplay(const char *display_name);
    XID XInternAtom(Display *display, const char *atom_name, int only_if_exists);
    XID XGetSelectionOwner(Display *display, XID atom);
    XID XCreateFontCursor(Display *display, unsigned int shape);
    int XDefineCursor(Display *display, XID window, XID cursor);
    int XFlush(Display *display);
    int XFreeCursor(Display *display, XID cursor);
    int XCloseDisplay(Display *display);
]]

local x11 = ffi.load('X11')

function systray_cursor.apply()
    local display = x11.XOpenDisplay(nil)
    if display == nil then return false end

    local atom = x11.XInternAtom(display, '_NET_SYSTEM_TRAY_S0', 1)
    local window = atom ~= 0 and x11.XGetSelectionOwner(display, atom) or 0
    if window == 0 then
        x11.XCloseDisplay(display)
        return false
    end

    -- XC_hand1 from X11/cursorfont.h. The tray's children inherit its cursor
    -- while retaining their own XEmbed mouse and click handling.
    local cursor = x11.XCreateFontCursor(display, 58)
    if cursor == 0 then
        x11.XCloseDisplay(display)
        return false
    end
    x11.XDefineCursor(display, window, cursor)
    x11.XFlush(display)
    x11.XFreeCursor(display, cursor)
    x11.XCloseDisplay(display)
    return true
end

return systray_cursor
