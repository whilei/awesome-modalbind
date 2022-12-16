-- awesome-modalbind - modal keybindings for awesomewm

local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local modalbind                           = {}
local wibox                               = require("wibox")
local awful                               = require("awful")
local beautiful                           = require("beautiful")
local gears                               = require("gears")
local nesting                             = 0
local verbose                             = false

--local functions

local defaults                            = {}

defaults.opacity                          = 1.0
defaults.height                           = 22
defaults.x_offset                         = 0
defaults.y_offset                         = 0
defaults.show_options                     = true
defaults.show_default_options             = true
defaults.position                         = "bottom_left"
defaults.honor_padding                    = true
defaults.honor_workarea                   = true

-- Clone the defaults for the used settings
local settings                            = {}
for key, value in pairs(defaults) do
	settings[key] = value
end

local prev_layout = nil

local aliases     = {}
aliases[" "]      = "space"

local function layout_swap(new)
	if type(new) == "number" and new >= 0 and new <= 3 then
		prev_layout = awesome.xkb_get_layout_group()
		awesome.xkb_set_layout_group(new)
	end
end

local function layout_return()
	if prev_layout ~= nil then
		awesome.xkb_set_layout_group(prev_layout)
		prev_layout = nil
	end
end

function modalbind.init()
	local modewibox = wibox({
								ontop   = true,
								visible = false,
								x       = 0,
								y       = 0,
								width   = 1,
								height  = 1,
								opacity = defaults.opacity,
								bg      = beautiful.modebox_bg or
										beautiful.bg_normal,
								fg      = beautiful.modebox_fg or
										beautiful.fg_normal,
								--shape=gears.shape.round_rect,
								type    = "toolbar"
							})

	modewibox:setup {
		{
			{
				id     = "title_name",
				widget = wibox.widget.textbox,
			},
			{
				--{
				--	SITE OF FUTURE TEXTBOX
				--},
				--{
				--	SITE OF FUTURE TEXTBOX
				--},
				id          = "textbox_container",

				layout      = wibox.layout.grid, -- I want boxes side-by-side.
				homogeneous = true,
				expand      = true,
				spacing     = 5,
				--min_cols_size = 10,
				--min_rows_size = 10,
			},
			id     = "valigner",
			layout = wibox.layout.align.vertical,
		},
		id      = "margin",
		margins = beautiful.modebox_border_width or
				beautiful.border_width,
		color   = beautiful.modebox_border or
				beautiful.border_focus,
		layout  = wibox.container.margin,
	}

	awful.screen.connect_for_each_screen(function(s)
		s.modewibox = modewibox
	end)
end

local function show_box(s, map, name)
	local mbox          = s.modewibox
	mbox.screen         = s

	local mar           = mbox:get_children_by_id("margin")[1]
	--local valignbox     = mbox:get_children_by_id("valigner")[1]
	local tbc           = mbox:get_children_by_id("textbox_container")[1]
	tbc.children        = {} -- reset because submenus want redraw
	local titlebox      = mbox:get_children_by_id("title_name")[1]

	-- "Layouts are collections of children widgets."

	local arrow_color   = '#47A590' -- faded teal
	local hotkey_color  = '#B162A0' -- faded pink
	local submenu_color = '#1479B1' -- blue

	-- First, lets do the title.
	if name == "" then
		name = "Modality"
	end
	if name ~= "" then
		titlebox:set_markup("<big><b>" .. name .. "</b></big>\n")
	end

	local function get_markup_for_entry(keyname, fn, action)
		if keyname == "separator" then
			return "\n"
		end
		if keyname == "onClose" then
			return ""
		end

		-- Abbreviate the key name so it looks like Spacemacs.
		keyname = string.gsub(keyname, "Return", "RET")
		keyname = string.gsub(keyname, "Space", "SPC")
		keyname = string.gsub(keyname, "Tab", "TAB")

		-- Handle configuration problems gracefully.
		if not action or action == "" then
			action = "???"
		end

		-- Assign the default markup value.
		local action_markup = "<span>" .. action .. "</span>"

		if action then
			local first_char      = string.sub(action, 1, 1)
			local is_submenu_name = first_char == '+'
			if is_submenu_name then
				action_markup = "<span foreground='" .. submenu_color .. "'>" .. action .. "</span>"
			end
		end

		return "<b><span> " ..
				'<span foreground="' .. hotkey_color .. '">' ..
				gears.string.xml_escape(keyname) ..
				'</span>' ..
				'</span>' ..
				"</b>" ..
				"<span foreground='" .. arrow_color .. "'> ➞ </span>" ..
				action_markup
	end

	--local function mapping_to_textbox(mapping)
	--end

	--local textboxes  = {}
	--local subtextbox = { layout = wibox.layout.align.vertical }

	if settings.show_options then

		local pair_count = 0
		for _, mapping in ipairs(map) do

			local m = get_markup_for_entry(mapping[1], mapping[2], mapping[3])
			if m ~= "" then
				local txtbx = wibox.widget.textbox()
				txtbx:set_markup_silently(m)
				--tbc:add(txtbx)
				-- https://awesomewm.org/apidoc/widget_layouts/wibox.layout.grid.html
				tbc:add_widget_at(txtbx, pair_count % 5 + 1, math.floor(pair_count / 5) + 1, 1) -- child, row, col, ~row_span, ~col_span

				pair_count = pair_count + 1
			end

			--if #subtextbox > 5 then
			--	table.insert(textboxes, subtextbox)
			--	subtextbox = { layout = wibox.layout.align.vertical }
			--end
		end
	end

	--textbox_container:add(textbox_parent)

	local x, y  = s.workarea.width / 2, 5 * 16 + 48
	mbox.width  = x + mar.left + mar.right
	mbox.height = math.max(settings.height, y + mar.top + mar.bottom)
	--mbox.width  = 1000
	--mbox.height = 300
	awful.placement.align(
			mbox,
			{
				position       = settings.position,
				honor_padding  = settings.honor_padding,
				honor_workarea = settings.honor_workarea,
				offset         = { x = settings.x_offset,
								   y = settings.y_offset }
			}
	)
	mbox.opacity = settings.opacity
	mbox.visible = true
end

local function hide_box()
	screen[1].modewibox.visible = false
end

local function mapping_for(keymap, key, use_lower)
	local k = key
	if use_lower then
		k = k:lower()
	end
	for _, mapping in ipairs(keymap) do
		local m = mapping[1]
		if use_lower then
			m = m:lower()
		end
		if m == k or
				(aliases[k] and m == k) then
			return mapping
		end
	end
	return nil
end

local function call_key_if_present(keymap, key, args, use_lower)
	local callback = mapping_for(keymap, key, use_lower)
	if callback then
		callback[2](args)
	end
end

function close_box(keymap, args)
	call_key_if_present(keymap, "onClose", args)
	keygrabber.stop()
	nesting = 0
	hide_box();
	layout_return()
end

function modalbind.close_box(keymap, args)
	return close_box(keymap, args)
end

function modalbind.keygrabber_stop()
	keygrabber.stop()
end

modalbind.default_keys = {
	{ "Escape", modalbind.close_box, "Exit Modal" },
	--{ "Return", modalbind.close_box, "Exit Modal" }
}

local function merge_default_keys(keymap)
	local result = {}
	for j, k in ipairs(modalbind.default_keys) do
		local no_add = false
		for i, m in ipairs(keymap) do
			if k[1] ~= "separator" and
					m[1] == k[1] then
				no_add = true
				break
			end
		end
		if not no_add then
			table.insert(result, k)
		end
	end
	for _, m in ipairs(keymap) do
		table.insert(result, m)
	end
	return result
end

function modalbind.grab(options)
	local keymap       = merge_default_keys(options.keymap or {})
	local name         = options.name
	local stay_in_mode = options.stay_in_mode or false
	local args         = options.args
	local layout       = options.layout
	local use_lower    = options.case_insensitive or false

	layout_swap(layout)
	if name then
		if settings.show_default_options then
			show_box(mouse.screen, keymap, name)
		else
			show_box(mouse.screen, options.keymap, name)
		end
		nesting = nesting + 1
	end
	call_key_if_present(keymap, "onOpen", args, use_lower)

	--if awful.keygrabber.is_running then
	--	awful.keygrabber:stop()
	--end
	keygrabber.run(function(mod, key, event)
		if event == "release" then
			return true
		end

		mapping = mapping_for(keymap, key, use_lower)
		if mapping then
			if (mapping[2] == close_box or
					mapping[2] == modalbind.close_box) then
				close_box(keymap, args)
				return true
			end

			keygrabber:stop()
			mapping[2](args)

			-- mapping "stay_in_mode" takes precedence over mode-wide setting
			if mapping["stay_in_mode"] ~= nil then
				stay_in_mode = mapping["stay_in_mode"]
			end

			if stay_in_mode then
				modalbind.grab { keymap       = keymap,
								 name         = name,
								 stay_in_mode = true,
								 args         = args,
								 use_lower    = use_lower }
			else
				nesting = nesting - 1
				if nesting < 1 then
					hide_box()
				end
				layout_return()
				return true
			end
		else
			if verbose then
				print("Unmapped key: \"" .. key .. "\"")
			end
		end

		return true
	end)
end

function modalbind.grabf(options)
	return function()
		modalbind.grab(options)
	end
end

--- Returns the wibox displaying the bound keys
function modalbind.modebox()
	return mouse.screen.modewibox
end

--- Change the opacity of the modebox.
-- @param amount opacity between 0.0 and 1.0, or nil to use default
function modalbind.set_opacity(amount)
	settings.opacity = amount or defaults.opacity
end

--- Change min height of the modebox.
-- @param amount height in pixels, or nil to use default
function modalbind.set_minheight(amount)
	settings.height = amount or defaults.height
end

--- Change horizontal offset of the modebox.
-- set location offset for the box. The box is shifted to the right
-- @param amount horizontal shift in pixels, or nil to use default
function modalbind.set_x_offset(amount)
	settings.x_offset = amount or defaults.x_offset
end

--- Change vertical offset of the modebox.
-- set location offset for the box. The box is shifted downwards.
-- @param amount vertical shift in pixels, or nil to use default
function modalbind.set_y_offset(amount)
	settings.y_offset = amount or defaults.y_offset
end

--- Set the position, where the modebox will be displayed
-- Allowed options are listed on page
-- https://awesomewm.org/apidoc/libraries/awful.placement.html#align
-- @param position of the widget
function modalbind.set_location(position)
	settings.position = position
end

---  enable displaying bindings for current mode
function modalbind.show_options()
	settings.show_options = true
end
--
---  disable displaying bindings for current mode
function modalbind.hide_options()
	settings.show_options = false
end
--
---  enable displaying bindings for current mode
function modalbind.show_default_options()
	settings.show_default_options = true
end
--
---  disable displaying bindings for current mode
function modalbind.hide_default_options()
	settings.show_default_options = false
end

---  set key aliases table
function modalbind.set_aliases(t)
	aliases = t
end

return modalbind
