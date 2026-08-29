local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

local tag_state = require("library.screen-tag-state")

local client_a = { valid = true }
local client_b = { valid = true }
local tag_1 = { index = 1, name = "1" }
local tag_3 = { index = 3, name = "3" }

function tag_1:clients()
    return { client_a, client_b }
end

function tag_3:clients()
    return { client_a }
end

local states = tag_state.collect({ tags = { tag_1, tag_3 } })
assert(#states == 2, "clients appearing on multiple tags must be collected once")
assert(states[1].client == client_a, "collection must preserve first-seen client order")
assert(#states[1].tag_indices == 2, "multi-tag client must retain every tag index")
assert(states[1].tag_indices[1] == 1 and states[1].tag_indices[2] == 3,
    "multi-tag indices must preserve source tag order")
assert(states[2].client == client_b and states[2].tag_indices[1] == 1,
    "single-tag client must retain its tag")

local target_1 = { index = 1 }
local target_3 = { index = 3 }
local mapped = tag_state.map({ tags = { target_1, {}, target_3 } }, states[1].tag_indices)
assert(#mapped == 2 and mapped[1] == target_1 and mapped[2] == target_3,
    "all available destination tags must be restored")
assert(tag_state.map({ tags = { target_1 } }, states[1].tag_indices) == nil,
    "partial destination tag mappings must be rejected")

local geometry = tag_state.fit_geometry(
    { x = 100, y = 50, width = 800, height = 600 },
    { x = 0, y = 0, width = 2880, height = 1800 },
    { x = 2880, y = 0, width = 2880, height = 1620 })
assert(geometry.x == 2980 and geometry.y == 50,
    "floating geometry must preserve its screen-relative position")
assert(geometry.width == 800 and geometry.height == 600,
    "floating geometry must preserve dimensions that fit the target")

local clamped = tag_state.fit_geometry(
    { x = 2500, y = 1500, width = 1000, height = 900 },
    { x = 0, y = 0, width = 2880, height = 1800 },
    { x = 2880, y = 0, width = 1920, height = 1080 })
assert(clamped.x == 3800 and clamped.y == 180,
    "floating geometry must remain inside a smaller target screen")

local source_file = assert(io.open(home .. "/.config/awesome/module/screen-manager.lua", "r"))
local source = source_file:read("*a")
source_file:close()
assert(not source:match("c:tags%(%{%}%)"), "screen migration must not clear all client tags")
assert(not source:match("state%.tag_index"), "screen migration must preserve complete tag sets")
assert(source:match("is_external_screen"), "screen migration must target the configured output")
assert(source:match("remaining%[c%] = state"), "failed restoration state must remain retryable")

print("Screen tag state tests passed")
