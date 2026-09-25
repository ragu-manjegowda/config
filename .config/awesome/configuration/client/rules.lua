local awful = require('awful')
local ruled = require('ruled')
local beautiful = require('beautiful')
local client_keys = require('configuration.client.keys')
local client_buttons = require('configuration.client.buttons')

ruled.client.connect_signal(
    'request::rules',
    function()
        -- All clients will match this rule.
        ruled.client.append_rule {
            id = 'global',
            rule = {},
            properties = {
                focus = awful.client.focus.filter,
                raise = true,
                floating = false,
                maximized = false,
                above = false,
                below = false,
                ontop = false,
                sticky = false,
                maximized_horizontal = false,
                maximized_vertical = false,
                keys = client_keys,
                buttons = client_buttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen
            }
        }

        ruled.client.append_rule {
            id         = 'round_clients',
            rule_any   = {
                type = {
                    'normal',
                    'dialog'
                }
            },
            except_any = {
                name = { 'Discord Updater' }
            },
            properties = {
                round_corners = true,
                shape = beautiful.client_shape_rounded
            }
        }

        -- Titlebar rules
        ruled.client.append_rule {
            id         = 'titlebars',
            rule_any   = {
                type = {
                    'normal',
                    'dialog',
                    'modal',
                    'utility'
                }
            },
            properties = {
                titlebars_enabled = true
            }
        }

        -- Dialogs
        ruled.client.append_rule {
            id = 'dialog',
            rule_any = {
                type  = { 'dialog' },
                class = { 'Wicd-client.py', 'calendar.google.com' }
            },
            properties = {
                titlebars_enabled = true,
                floating = true,
                above = true,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen
            }
        }

        -- Firefox now opens file choosers through xdg-desktop-portal-gtk.
        ruled.client.append_rule {
            id = 'portal_file_chooser',
            rule = {
                class = 'Xdg-desktop-portal-gtk',
                role = 'GtkFileChooserDialog'
            },
            callback = function(c)
                local area = c.screen.workarea
                if c.transient_for and c.transient_for.valid then
                    area = c.transient_for:geometry()
                end
                c:geometry {
                    width = math.floor(area.width * 0.8),
                    height = math.floor(area.height * 0.8)
                }
            end
        }

        -- Modals
        ruled.client.append_rule {
            id = 'modal',
            rule_any = {
                type = { 'modal' }
            },
            properties = {
                titlebars_enabled = true,
                floating = true,
                above = true,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen
            }
        }

        -- Utilities
        ruled.client.append_rule {
            id = 'utility',
            rule_any = {
                type = { 'utility' }
            },
            properties = {
                titlebars_enabled = false,
                floating = true,
                skip_decoration = true,
                placement = awful.placement.centered
            }
        }

        -- Splash
        ruled.client.append_rule {
            id = 'splash',
            rule_any = {
                type = { 'splash' },
                name = { 'Discord Updater' }
            },
            properties = {
                titlebars_enabled = false,
                round_corners = false,
                floating = true,
                above = true,
                skip_decoration = true,
                placement = awful.placement.centered
            }
        }

        ruled.client.append_rule {
            id = 'cisco',
            rule_any = {
                class = {
                    'com.cisco.anyconnect.gui',
                    'Com.cisco.anyconnect.gui'
                },
            },
            properties = {
                skip_taskbar = true,
                titlebars_enabled = false,
            }
        }

        ruled.client.append_rule {
            id         = 'floating_windows',
            rule_any   = {
                instance = {
                    'stocks',
                },
            },
            properties = {
                titlebars_enabled = true,
                skip_decoration = true,
                floating = true,
                placement = awful.placement.centered,
                sticky = true,
                ontop = true,
            }
        }

        -- Terminal emulators
        ruled.client.append_rule {
            id = 'terminals',
            rule_any = {
                instance = {
                    'terminal_no_title'
                },
            },
            properties = {
                size_hints_honor = false,
                titlebars_enabled = false,
                opacity = 0.8
            }
        }

        -- Image viewers
        ruled.client.append_rule {
            id         = 'image_viewers',
            rule_any   = {
                class = {
                    -- 'feh',
                    'Pqiv',
                    'Sxiv'
                },
            },
            properties = {
                titlebars_enabled = true,
                skip_decoration = true,
                floating = true,
                ontop = true,
                placement = awful.placement.centered
            }
        }

        -- Floating
        ruled.client.append_rule {
            id         = 'floating',
            rule_any   = {
                instance = {
                    'file_progress',
                    'Popup',
                    'nm-connection-editor',
                },
                class    = {
                    'scrcpy',
                    'Mugshot',
                    'Pulseeffects'
                },
                role     = {
                    'AlarmWindow',
                    'ConfigManager',
                    'pop-up'
                }
            },
            properties = {
                titlebars_enabled = true,
                skip_decoration = true,
                ontop = true,
                floating = true,
                focus = awful.client.focus.filter,
                raise = true,
                keys = client_keys,
                buttons = client_buttons,
                placement = awful.placement.centered
            }
        }
    end
)

-- Normally we'd do this with a rule, but some program like spotify doesn't
-- set its class or name until it starts up, we need to catch that signal.
client.connect_signal(
    'property::class',
    function(c)
        if c.class == 'Spotify' then
            local window_mode = not c.fullscreen

            -- Check if fullscreen or window mode
            if c.fullscreen then
                c.fullscreen = false
            end

            -- Check if Spotify is already open
            local app = function(_)
                return ruled.client.match(c, { class = 'Spotify' })
            end

            local app_count = 0
            for _ in awful.client.iterate(app) do
                app_count = app_count + 1
            end

            -- If Spotify is already open, don't open a new instance
            if app_count > 1 then
                c:kill()
                -- Switch to previous instance
                for client in awful.client.iterate(app) do
                    client:jump_to(false)
                end
            else
                -- Move the instance to specified tag on this screen
                local t = awful.tag.find_by_name(awful.screen.focused(), '5')
                c:move_to_tag(t)
                t:view_only()

                -- Fullscreen mode if not window mode
                if not window_mode then
                    c.fullscreen = true
                else
                    c.floating = true
                    awful.placement.centered(c, { honor_workarea = true })
                end
            end
        end
    end
)
