local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local M = {}

local function popup_height_for_items(item_count)
	return (beautiful.popup_menu_padding * 2)
		+ beautiful.popup_menu_header_height
		+ beautiful.popup_menu_spacing
		+ (item_count * beautiful.popup_menu_item_height)
end

local function build_item(item)
	local content = wibox.widget({
		{
			text = item.text,
			widget = wibox.widget.textbox,
			font = beautiful.font,
			align = "left",
			valign = "center",
		},
		left = beautiful.popup_menu_item_padding,
		right = beautiful.popup_menu_item_padding,
		widget = wibox.container.margin,
	})

	if not item.selected then
		return content
	end

	return wibox.widget({
		{
			content,
			forced_height = beautiful.popup_menu_item_height,
			widget = wibox.container.constraint,
		},
		bg = beautiful.popup_menu_item_bg,
		border_width = beautiful.border_width,
		border_color = beautiful.popup_menu_item_border,
		shape = gears.shape.rectangle,
		widget = wibox.container.background,
	})
end

local function build_backdrops(on_cancel)
	local backdrops = {}
	local buttons

	if on_cancel then
		buttons = gears.table.join(
			awful.button({}, 1, on_cancel),
			awful.button({}, 2, on_cancel),
			awful.button({}, 3, on_cancel)
		)
	end

	for s in screen do
		local backdrop = wibox({
			screen = s,
			visible = true,
			ontop = true,
			bg = beautiful.popup_menu_backdrop_bg,
			x = s.geometry.x,
			y = s.geometry.y,
			width = s.geometry.width,
			height = s.geometry.height,
			widget = wibox.container.background(),
		})

		if buttons then
			backdrop:buttons(buttons)
		end

		backdrops[#backdrops + 1] = backdrop
	end

	return backdrops
end

local function build_popup(args)
	local title_widget = wibox.widget({
		markup = "<b>" .. gears.string.xml_escape(args.title or "") .. "</b>",
		widget = wibox.widget.textbox,
		font = beautiful.font,
	})
	local items_widget = wibox.widget({
		spacing = beautiful.popup_menu_item_spacing,
		layout = wibox.layout.fixed.vertical,
	})
	local backdrops = build_backdrops(args.on_cancel)
	local popup = awful.popup({
		screen = args.screen,
		visible = true,
		ontop = true,
		border_width = beautiful.border_width,
		border_color = beautiful.popup_menu_border,
		bg = beautiful.popup_menu_bg,
		fg = beautiful.popup_menu_fg,
		minimum_width = beautiful.popup_menu_width,
		maximum_width = beautiful.popup_menu_width,
		minimum_height = popup_height_for_items(0),
		maximum_height = popup_height_for_items(0),
		placement = awful.placement.centered,
		widget = {
			{
				title_widget,
				items_widget,
				spacing = beautiful.popup_menu_spacing,
				layout = wibox.layout.fixed.vertical,
			},
			margins = beautiful.popup_menu_padding,
			widget = wibox.container.margin,
		},
	})
	local closed = false
	local last_state = { title = args.title, items = {} }

	function popup:update(state)
		last_state = state or last_state
		title_widget.markup = "<b>" .. gears.string.xml_escape(last_state.title or "") .. "</b>"
		items_widget:reset()

		for _, item in ipairs(last_state.items or {}) do
			items_widget:add(build_item(item))
		end

		local height = popup_height_for_items(#(last_state.items or {}))
		self.minimum_height = height
		self.maximum_height = height
	end

	function popup:refresh_theme()
		if closed then
			return
		end

		self.border_width = beautiful.border_width
		self.border_color = beautiful.popup_menu_border
		self.bg = beautiful.popup_menu_bg
		self.fg = beautiful.popup_menu_fg
		self.minimum_width = beautiful.popup_menu_width
		self.maximum_width = beautiful.popup_menu_width
		self:update(last_state)
	end

	function popup:close()
		if closed then
			return
		end

		closed = true
		self.visible = false

		for _, backdrop in ipairs(backdrops) do
			backdrop.visible = false
		end

		if self._theme_reload_handler then
			awesome.disconnect_signal("theme::reload", self._theme_reload_handler)
			self._theme_reload_handler = nil
		end
	end

	popup._theme_reload_handler = function()
		popup:refresh_theme()
	end
	awesome.connect_signal("theme::reload", popup._theme_reload_handler)

	return popup
end

local function normalize_key(key)
	return key == " " and "space" or key
end

local function binding_matches(mod, key, binding)
	if normalize_key(binding.key) ~= normalize_key(key) then
		return false
	end

	for _, modifier in ipairs(binding.modifiers or {}) do
		if not mod[modifier] then
			return false
		end
	end

	return true
end

local function entry_text(entry, args)
	return (args.text and args.text(entry, args)) or entry.text or ""
end

local function entry_match_text(entry, args)
	local text = entry.match_text
	if text == nil then
		text = entry_text(entry, args)
	end

	return tostring(text):lower()
end

local function rebuild_active_entries(state)
	local lowered_query = state.query:lower()
	local active_entries = {}

	for _, entry in ipairs(state.args.entries) do
		local text = entry_match_text(entry, state.args)
		if lowered_query == "" or text:sub(1, #lowered_query) == lowered_query or text:find(lowered_query, 1, true) then
			active_entries[#active_entries + 1] = entry
		end
	end

	state.active_entries = active_entries
end

local function update_popup(state)
	local items = {}

	for index, entry in ipairs(state.active_entries) do
		items[#items + 1] = {
			text = entry_text(entry, state.args),
			selected = index == state.current_index,
		}
	end

	state.popup:update({
		title = state.args.title,
		items = items,
	})
end

local function preview_current(state)
	local entry = state.active_entries[state.current_index]

	state.preview_generation = state.preview_generation + 1
	update_popup(state)

	if not (entry and state.args.preview) then
		return
	end

	if state.args.preview_delay_ms <= 0 then
		state.args.preview(entry, state.transaction, state.args)
		return
	end

	local generation = state.preview_generation
	gears.timer({
		timeout = state.args.preview_delay_ms / 1000,
		autostart = true,
		single_shot = true,
		callback = function()
			if state.finished or state.closed then
				return
			end

			if generation == state.preview_generation and state.active_entries[state.current_index] == entry then
				state.args.preview(entry, state.transaction, state.args)
			end
		end,
	})
end

local function apply_query(state, query)
	local previous_entry = state.active_entries[state.current_index]

	state.query = query or ""
	rebuild_active_entries(state)

	if #state.active_entries == 0 then
		state.current_index = 1
	elseif previous_entry then
		for index, entry in ipairs(state.active_entries) do
			if entry == previous_entry then
				state.current_index = index
				break
			end
		end

		if state.current_index < 1 or state.current_index > #state.active_entries then
			state.current_index = 1
		end
	else
		state.current_index = math.max(1, math.min(state.current_index, #state.active_entries))
	end

	preview_current(state)
end

local function step(state, direction)
	if #state.active_entries == 0 then
		return
	end

	local count = #state.active_entries
	state.current_index = ((state.current_index - 1 + direction) % count) + 1
	preview_current(state)
end

local function finish(state, action)
	if state.finished then
		return
	end

	state.finished = true
	state.closed = true
	awful.keygrabber.stop()
	state.promptbox:set_markup("")
	state.popup:close()

	local entry = state.active_entries[state.current_index]

	if action == "commit" then
		if entry and state.args.commit then
			state.args.commit(entry, state.transaction, state.args)
		end
		return
	end

	if state.args.rollback then
		state.args.rollback(state.transaction, state.args)
	end
end

function M.run(args)
	local state = {
		args = {
			title = args.title,
			screen = args.screen or awful.screen.focused(),
			promptbox = args.promptbox,
			advance_keys = args.advance_keys or {},
			entries = args.entries or {},
			text = args.text,
			current_index = args.current_index or 1,
			query = args.query or "",
			preview_delay_ms = args.preview_delay_ms or 0,
			snapshot = args.snapshot,
			rollback = args.rollback,
			preview = args.preview,
			commit = args.commit,
		},
		active_entries = {},
		query = args.query or "",
		current_index = args.current_index or 1,
		transaction = nil,
		popup = nil,
		promptbox = args.promptbox,
		preview_generation = 0,
		closed = false,
		finished = false,
	}

	if not state.promptbox then
		local prompt_screen = state.args.screen
		if prompt_screen and prompt_screen.mypromptbox and prompt_screen.mypromptbox.widget then
			state.promptbox = prompt_screen.mypromptbox.widget
		else
			state.promptbox = wibox.widget.textbox()
		end
	end

	state.popup = build_popup({
		title = state.args.title,
		screen = state.args.screen,
		on_cancel = function()
			finish(state, "cancel")
		end,
	})
	state.transaction = state.args.snapshot and state.args.snapshot(state.args) or nil

	rebuild_active_entries(state)
	if #state.active_entries == 0 then
		state.current_index = 1
	elseif state.current_index < 1 or state.current_index > #state.active_entries then
		state.current_index = 1
	end
	preview_current(state)

	awful.prompt.run({
		prompt = (state.args.title or "") .. ": ",
		textbox = state.promptbox,
		hooks = {
			{
				{},
				"space",
				function(command)
					return command
				end,
			},
			{
				{},
				" ",
				function(command)
					return command
				end,
			},
		},
		changed_callback = function(input)
			apply_query(state, input)
		end,
		keypressed_callback = function(mod, key)
			for _, binding in ipairs(state.args.advance_keys) do
				if binding_matches(mod, key, binding) then
					step(state, binding.direction or 1)
					return true
				end
			end

			if key == "Up" or key == "Left" then
				step(state, -1)
				return true
			end

			if key == "Down" or key == "Right" then
				step(state, 1)
				return true
			end

			if key == "Escape" then
				finish(state, "cancel")
				return false
			end

			return false
		end,
		exe_callback = function()
			finish(state, "commit")
		end,
		done_callback = function()
			if not state.finished then
				finish(state, "cancel")
			end
		end,
	})

	return state
end

return M
