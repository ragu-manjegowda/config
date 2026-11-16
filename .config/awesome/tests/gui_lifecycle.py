"""Exercise widget collection and subprocess bounds in a real Awesome desktop."""

import time
import unittest

from gui_centers import CenterGuiFixture


class LifecycleGuiTests(CenterGuiFixture):
    def test_subscriber_spawn_failure_rearms_real_timer(self):
        self.lua(
            """
            local gears = require('gears')
            local spawn = require('awful').spawn
            local original_timer, original_spawn = gears.timer, spawn.with_line_callback
            local retry_timer
            gears.timer = function(spec)
                retry_timer = original_timer(spec)
                return retry_timer
            end
            spawn.with_line_callback = function() return 'Fixture spawn failure' end
            local loaded, result = pcall(dofile,
                gears.filesystem.get_configuration_dir() .. 'library/audio-monitor.lua')
            gears.timer = original_timer
            assert(loaded, result)
            retry_timer:emit_signal('timeout')
            local rearmed = retry_timer.started
            retry_timer:stop()
            spawn.with_line_callback = original_spawn
            assert(rearmed, 'A synchronous spawn failure cancelled its own reconnect timer')
            """
        )

    def test_removed_screen_panels_are_collectible(self):
        self.lua(
            """
            function gui_test.info_callbacks()
                local callbacks = require('widget.email')._signals['widget::layout_changed'].strong
                local count = 0
                for callback in pairs(callbacks) do
                    if debug.getinfo(callback, 'S').source:find('layout/info%-center/init.lua') then
                        count = count + 1
                    end
                end
                return count
            end
            gui_test.baseline_callbacks = gui_test.info_callbacks()
            gui_test.removed_panels = setmetatable({}, { __mode = 'v' })
            """
        )
        for cycle in range(1, 11):
            self.lua(
                f"""
                local display = screen.fake_add(1920, 0, 1280, 800)
                gui_test.removed_panels[{cycle}] = assert(display.info_center)
                display:fake_remove()
                """
            )
        time.sleep(0.5)
        self.lua(
            """
            collectgarbage('collect'); collectgarbage('collect')
            assert(screen.count() == 1)
            assert(gui_test.info_callbacks() == gui_test.baseline_callbacks,
                'Removed screens retained Info Center callbacks')
            assert(next(gui_test.removed_panels) == nil, 'Removed Info Centers were not collected')
            """
        )

    def test_discarded_status_views_are_collectible(self):
        self.lua(
            """
            gui_test.discarded_views = setmetatable({}, { __mode = 'v' })
            gui_test.live_views = {}
            local factories = { require('widget.tray-toggle'), require('widget.vpn'),
                (require('widget.kbd-battery')) }
            for kind, factory in ipairs(factories) do
                gui_test.live_views[kind] = factory()
                for index = 1, 20 do
                    gui_test.discarded_views[kind * 100 + index] = factory()
                end
            end
            """
        )
        time.sleep(0.5)
        self.lua(
            """
            collectgarbage('collect'); collectgarbage('collect')
            assert(next(gui_test.discarded_views) == nil, 'Discarded status widgets were retained')
            awesome.emit_signal('module::vpn_status', 'connected', 'namespace')
            awesome.emit_signal('module::kbd_battery_status', true, 70, 80)
            assert(gui_test.live_views[2].visible and gui_test.live_views[3].visible,
                'Live widgets lost their signal handlers after collection')
            """
        )

    def test_hidden_bluetooth_does_not_resume_polling(self):
        def requests():
            return sum(
                "rfkill list bluetooth" in command
                for command in self.state()["requests"]
            )

        self.assertFalse(self.state()["control"]["visible"])
        initial = requests()
        time.sleep(5.25)
        self.assertEqual(requests(), initial, "Hidden widget polled at startup")
        self.lua(
            "gui_test.scenario = 'slow'; "
            "screen.primary.control_center:toggle(); screen.primary.control_center:toggle()"
        )
        after_show = requests()
        self.assertEqual(after_show, initial + 1)
        time.sleep(5.5)
        self.assertFalse(self.state()["control"]["visible"])
        self.assertEqual(requests(), after_show, "Late completion restarted hidden polling")

    def test_audio_event_burst_has_bounded_subprocesses(self):
        self.lua(
            """
            gui_test.scenario = 'slow'
            gui_test.audio_burst_start = #gui_test.requests
            local monitor = require('library.audio-monitor')
            for index = 1, 30 do
                monitor:emit_signal('sink')
                monitor:emit_signal('source', 'change', 283)
            end
            local count = 0
            for index = gui_test.audio_burst_start + 1, #gui_test.requests do
                if gui_test.requests[index]:find('audio%-control') then count = count + 1 end
            end
            assert(count == 2, 'Audio event burst must start one reader per device kind')
            """
        )
        time.sleep(1)
        self.lua(
            """
            local count = 0
            for index = gui_test.audio_burst_start + 1, #gui_test.requests do
                if gui_test.requests[index]:find('audio%-control') then count = count + 1 end
            end
            assert(count == 4, 'Audio event burst must produce one fresh follow-up per device kind')
            """
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
