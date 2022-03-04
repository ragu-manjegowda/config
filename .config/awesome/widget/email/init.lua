local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/email/icons/'

local config = require('configuration.config')
local secrets = {
	email_address = config.widget.email.address,
	app_password = config.widget.email.app_password,
	imap_server = config.widget.email.imap_server,
	port = config.widget.email.port
}

local mails_path = config_dir .. 'widget/email/mails.txt'

local unread_email_count = 0
local startup_show = true

local scroll_container = function(widget)
	return wibox.widget {
		widget,
		id = 'scroll_container',
		max_size = 345,
		speed = 75,
		expand = true,
		direction = 'h',
		step_function = wibox.container.scroll
						.step_functions.waiting_nonlinear_back_and_forth,
		fps = 30,
		layout = wibox.container.scroll.horizontal,
	}
end

local email_icon_widget = wibox.widget {
	{
		id = 'icon',
		image = widget_icon_dir .. 'email.svg',
		resize = true,
		forced_height = dpi(45),
		forced_width = dpi(45),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal
}

local email_header = wibox.widget {
	text   = 'Email',
	font   = 'Hack Nerd Bold 14',
	align  = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_from_text = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'From:',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}


local email_recent_from = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'loading@stdout.sh',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_subject_text = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'Subject:',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_recent_subject = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'Loading data',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_date_text = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'Local Date:',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_recent_date = wibox.widget {
	font = 'Hack Nerd Regular 10',
	markup = 'Loading date...',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local email_report = wibox.widget{
	{
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(10),
			email_header,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(10),
				{
					layout = wibox.layout.align.vertical,
					expand = 'none',
					nil,
					email_icon_widget,
					nil
				},
				{
					layout = wibox.layout.align.vertical,
					expand = 'none',
					nil,
					{
						layout = wibox.layout.fixed.vertical,
						{
							email_from_text,
							scroll_container(email_recent_from),
							spacing = dpi(5),
							layout = wibox.layout.fixed.horizontal
						},
						{
							email_subject_text,
							scroll_container(email_recent_subject),
							spacing = dpi(5),
							layout = wibox.layout.fixed.horizontal
						},
						{
							email_date_text,
							scroll_container(email_recent_date),
							spacing = dpi(5),
							layout = wibox.layout.fixed.horizontal
						}
					},
					nil
				}
			}
		},
		margins = dpi(10),
		widget = wibox.container.margin
	},
	forced_height = dpi(110),
	bg = beautiful.groups_bg,
	shape = function(cr, width, height)
		gears.shape.partially_rounded_rect(cr, width, height, true, true, true, true, beautiful.groups_radius)
	end,
	widget = wibox.container.background
}

local email_details_tooltip = awful.tooltip
{
	text = 'Loading...',
	objects = {email_icon_widget},
	mode = 'outside',
	align = 'right',
	preferred_positions = {'left', 'right', 'top', 'bottom'},
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8)
}

local notify_all_unread_email = function(email_data)

	local unread_counter = email_data:match('Unread Count: (.-)From:'):sub(1, -2)

	local email_data = email_data:match('(From:.*)'):sub(1, -2)

	local title = nil

	if tonumber(unread_email_count) > 1 then
		title = 'You have ' .. unread_counter .. ' unread emails!'
	else
		title = 'You have ' .. unread_counter .. ' unread email!'
	end

	naughty.notification ({
		app_name = 'Email',
		title = title,
		icon = widget_icon_dir .. 'email-unread.svg'
	})
end

local notify_new_email = function(count, from, subject)
	if not startup_show and (tonumber(count) > tonumber(unread_email_count)) then
		unread_email_count = tonumber(count)

		local message = "From: " .. from ..
		"\nSubject: " .. subject

		naughty.notification ({
			app_name = 'Email',
			title = 'You have a new unread email!',
			message = message,
			timeout = 10,
			icon = widget_icon_dir .. 'email-unread.svg'
		})
	else
		unread_email_count = tonumber(count)
	end

end

local set_email_data_tooltip = function(email_data)
	local email_data = email_data:match('(From:.*)')
	local counter = "<span font='Hack Nerd Regular 10'>Unread Count: </span>" .. unread_email_count
	email_details_tooltip:set_markup(counter .. '\n\n' .. email_data)
end

local set_widget_markup = function(from, subject, date, tooltip)

	email_recent_from:set_markup(from:gsub('%\n', ''))
	email_recent_subject:set_markup(subject:gsub('%\n', ''))
	email_recent_date:set_markup(date:gsub('%\n', ''))

	if tooltip then
		email_details_tooltip:set_markup(tooltip)
	end
end

local set_no_connection_msg = function()
	set_widget_markup(
		'message@stderr.sh',
		'Check network connection!',
		os.date('%d-%m-%Y %H:%M:%S'),
		'No internet connection!'
	)
end

local set_invalid_credentials_msg = function()
	set_widget_markup(
		'message@stderr.sh',
		'Invalid Credentials!',
		os.date('%d-%m-%Y %H:%M:%S'),
		'You have an invalid credentials!'
	)
end

local set_latest_email_data = function(email_data)

	local unread_count = email_data:match('Unread Count: (.-)From:'):sub(1, -2)
	local recent_from = email_data:match('From: (.-)Subject:'):sub(1, -2)
	local recent_subject = email_data:match('Subject: (.-)Local Date:'):sub(1, -2)
	local recent_date = email_data:match('Local Date: (.-)\n')

	recent_from = recent_from:match('<(.*)>') or recent_from:match('&lt;(.*)&gt;') or recent_from

	local count = tonumber(unread_count)
	if count > 0 and count <= 9 then
		email_icon_widget.icon:set_image(widget_icon_dir .. 'email-'.. tostring(count) .. '.svg')
	elseif count > 9 then
		email_icon_widget.icon:set_image(widget_icon_dir .. 'email-9+.svg')
	end

	set_widget_markup(
		recent_from,
		recent_subject,
		recent_date
	)

	notify_new_email(unread_count, recent_from, recent_subject)
end

local set_empty_inbox_msg = function()
	set_widget_markup(
		'empty@stdout.sh',
		'Empty inbox',
		os.date('%d-%m-%Y %H:%M:%S'),
		'Empty inbox.'
	)
end

awesome.connect_signal(
	'module::email:show',
    function()
        fetch_email_data()
    end
)

function fetch_email_data()
    open = io.open
    file = open(tostring(mails_path), "rb") -- r read mode and b binary mode

    if not file then return end

    content = file:read "*a" -- *a or *all reads the whole file
    file:close()

	stdout = content

	if stdout:match('Temporary failure in name resolution') then
		set_no_connection_msg()
		return
	elseif stdout:match('Invalid credentials') then
		set_invalid_credentials_msg()
		return
	elseif stdout:match('Unread Count: 0') then
		email_icon_widget.icon:set_image(widget_icon_dir .. 'email.svg')
		set_empty_inbox_msg()
		return
	elseif not stdout:match('Unread Count: (.-)From:') then
		return
	elseif not stdout or stdout == '' then
		return
	end

	set_latest_email_data(stdout)
	set_email_data_tooltip(stdout)

	if startup_show then
		notify_all_unread_email(stdout)
		startup_show = false
	end
end

local set_missing_secrets_msg = function()
	set_widget_markup(
		'message@stderr.sh',
		'Credentials are missing!',
		os.date('%d-%m-%Y %H:%M:%S'),
		'Missing credentials!'
	)
end

local check_secrets = function()
	if secrets.email_address == '' and secrets.app_password == '' and secrets.imap_server == '' and secrets.port == '' then
		set_missing_secrets_msg()
		return
	else
		fetch_email_data()
	end
end

check_secrets()

email_report:connect_signal(
	'mouse::enter',
	function()
		check_secrets()
	end
)

awesome.connect_signal(
	'system::network_connected',
	function()
		gears.timer.start_new(
			5,
			function()
				check_secrets()
			end
		)
	end
)

return email_report
