-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local GLib = require("lgi").GLib
local gobject = require("gears.object")
local gtable = require("gears.table")
local subscribable = require("library.tween.subscribable")
local tween = require("library.tween.tween")
local table = table
local pairs = pairs

local animation_manager = {}
animation_manager.easing = {
	linear = "linear",
	inQuad = "inQuad",
	outQuad = "outQuad",
	inOutQuad = "inOutQuad",
	outInQuad = "outInQuad",
	inCubic = "inCubic",
	outCubic = "outCubic",
	inOutCubic = "inOutCubic",
	outInCubic = "outInCubic",
	inQuart = "inQuart",
	outQuart = "outQuart",
	inOutQuart = "inOutQuart",
	outInQuart = "outInQuart",
	inQuint = "inQuint",
	outQuint = "outQuint",
	inOutQuint = "inOutQuint",
	outInQuint = "outInQuint",
	inSine = "inSine",
	outSine = "outSine",
	inOutSine = "inOutSine",
	outInSine = "outInSine",
	inExpo = "inExpo",
	outExpo = "outExpo",
	inOutExpo = "inOutExpo",
	outInExpo = "outInExpo",
	inCirc = "inCirc",
	outCirc = "outCirc",
	inOutCirc = "inOutCirc",
	outInCirc = "outInCirc",
	inElastic = "inElastic",
	outElastic = "outElastic",
	inOutElastic = "inOutElastic",
	outInElastic = "outInElastic",
	inBack = "inBack",
	outBack = "outBack",
	inOutBack = "inOutBack",
	outInBack = "outInBack",
	inBounce = "inBounce",
	outBounce = "outBounce",
	inOutBounce = "inOutBounce",
	outInBounce = "outInBounce",
}

local animation = {}

local instance = nil

local ANIMATION_FRAME_DELAY = 16

local function micro_to_milli(micro)
	return micro / 1000
end

local function second_to_micro(sec)
	return sec * 1000000
end

local function second_to_milli(sec)
	return sec * 1000
end

function animation:start(args)
	args = args or {}

	-- Awestoer/Rubbto compatibility
	-- I'd rather this always be a table, but Awestoer/Rubbto
	-- except the :set() method to have 1 number value parameter
	-- used to set the target
	local is_table = type(args) == "table"
	local initial = is_table and (args.pos or self.pos) or self.pos
	local subject = is_table and (args.subject or self.subject) or self.subject
	local target = is_table and (args.target or self.target) or args
	local duration = is_table and (args.duration or self.duration) or self.duration
	local easing = is_table and (args.easing or self.easing) or self.easing

	duration = self._private.anim_manager._private.instant == true and 0.01 or duration

	if self.tween == nil or self.reset_on_stop == true then
		self.tween = tween.new({
			initial = initial,
			subject = subject,
			target = target,
			duration = second_to_micro(duration),
			easing = easing,
		})
	end

	if not self._private.registered then
		table.insert(self._private.anim_manager._private.animations, self)
		self._private.registered = true
	end

	self.state = true
	self.last_elapsed = GLib.get_monotonic_time()

	self.started:fire()
	self:emit_signal("started")
	self._private.anim_manager:_start_scheduler()
end

function animation:set(args)
	self:start(args)
	self:emit_signal("set")
end

function animation:stop()
	self.state = false
	self._private.anim_manager:_remove(self)
	self:emit_signal("stopped")
end

function animation:abort(reset)
	self:stop()
	if reset and self.tween then
		self.tween:reset()
		self.pos = self._private.initial
		self:fire(self.pos)
		self:emit_signal("update", self.pos)
	end
	self:emit_signal("aborted")
end

function animation:initial()
	return self._private.initial
end

function animation_manager:set_instant(value)
	self._private.instant = value
end

function animation_manager:new(args)
	args = args or {}

	args.pos = args.pos or 0
	args.subject = args.subject or nil
	args.target = args.target or nil
	args.duration = args.duration or 0
	args.easing = args.easing or nil
	args.loop = args.loop or false
	args.signals = args.signals or {}
	args.update = args.update or nil
	args.reset_on_stop = args.reset_on_stop == nil and true or args.reset_on_stop

    -- Duration 0 is coming from awesome notification timeout
    -- during which awesome set loop as true
    if args.loop == true and args.duration == 0 then
        args.duration = 5
        args.easing = animation_manager.easing.inOutBounce
    end

	-- Awestoer/Rubbto compatibility
	args.subscribed = args.subscribed or nil
	local ret = subscribable()
	ret.started = subscribable()
	ret.ended = subscribable()
	if args.subscribed ~= nil then
		ret:subscribe(args.subscribed)
	end

	for sig, sigfun in pairs(args.signals) do
		ret:connect_signal(sig, sigfun)
	end
	if args.update ~= nil then
		ret:connect_signal("update", args.update)
	end

	gtable.crush(ret, args, true)
	gtable.crush(ret, animation, true)

	ret._private = {}
	ret._private.anim_manager = self
	ret._private.initial = args.pos
	ret._private.registered = false

	return ret
end

function animation_manager:_remove(target)
	for index = #self._private.animations, 1, -1 do
		if self._private.animations[index] == target then
			table.remove(self._private.animations, index)
			target._private.registered = false
			return
		end
	end
end

function animation_manager:_start_scheduler()
	if self._private.source_id then
		return
	end

	self._private.source_id = GLib.timeout_add(
		GLib.PRIORITY_DEFAULT,
		ANIMATION_FRAME_DELAY,
		function()
			for index = #self._private.animations, 1, -1 do
				local current = self._private.animations[index]
				if current.state then
					local time = GLib.get_monotonic_time()
					local delta = time - current.last_elapsed
					current.last_elapsed = time

					local pos = current.tween:update(delta)
					if pos == true then
						if current.loop then
							current.tween:reset()
						else
							current.pos = current.tween.target
							current:fire(current.pos)
							current:emit_signal("update", current.pos)
							current.state = false
							current.ended:fire(current.pos)
							table.remove(self._private.animations, index)
							current._private.registered = false
							current:emit_signal("ended", current.pos)
						end
					else
						current.pos = pos
						current:fire(current.pos)
						current:emit_signal("update", current.pos)
					end
				else
					table.remove(self._private.animations, index)
					current._private.registered = false
				end
			end

			if #self._private.animations == 0 then
				self._private.source_id = nil
				return false
			end

			return true
		end
	)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, animation_manager, true)

	ret._private = {}
	ret._private.animations = {}
	ret._private.instant = false
	ret._private.source_id = nil

	return ret
end

if not instance then
	instance = new()
end
return instance
