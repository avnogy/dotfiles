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
	if key == " " then
		return "space"
	end

	return key
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

local function normalize_rendered_item(rendered)
	if type(rendered) == "string" then
		return { text = rendered }
	end

	return rendered or {}
end

local function normalize_entry(raw_entry, ctx)
	local display_text = ctx.text(raw_entry, ctx) or raw_entry.text or ""
	local match_text = raw_entry.match_text

	if match_text == nil then
		match_text = display_text
	end

	return {
		raw = raw_entry,
		text = display_text,
		match_text = tostring(match_text):lower(),
	}
end

local function ensure_normalized_entry(entry, ctx)
	if entry == nil then
		return nil
	end

	if entry.raw ~= nil and entry.text ~= nil and entry.match_text ~= nil then
		return entry
	end

	return ctx.normalized_entry_map[entry] or normalize_entry(entry, ctx)
end

local function entry_match_text(entry)
	if entry.match_text ~= nil then
		return tostring(entry.match_text):lower()
	end

	if entry.text ~= nil then
		return tostring(entry.text):lower()
	end

	return ""
end

local function default_match(entry, query)
	local lowered = query:lower()
	local text = entry_match_text(entry)

	return lowered == "" or text:sub(1, #lowered) == lowered or text:find(lowered, 1, true) ~= nil
end

local function default_filter(ctx)
	local active_entries = {}

	for _, entry in ipairs(ctx.entries) do
		if ctx.matcher(entry, ctx.query, ctx) then
			active_entries[#active_entries + 1] = ctx.normalized_entry_map[entry] or normalize_entry(entry, ctx)
		end
	end

	return active_entries
end

local function build_prompt_hooks()
	return {
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
	}
end

function M.new(args)
	local chooser = {
		screen = args.screen or awful.screen.focused(),
		title = args.title,
		prompt = (args.prompt_title or args.title) .. ": ",
		advance_keys = args.advance_keys or {},
		query = args.query or "",
		current_index = args.current_index or 1,
		text = args.text or function(entry)
			return entry.text or ""
		end,
		render = args.render,
		matcher = args.matcher or default_match,
		filter = args.filter or args.recalculate or default_filter,
		preview = args.preview,
		snapshot = args.snapshot,
		commit = args.commit,
		rollback = args.rollback,
		entries = args.entries or {},
		normalized_entries = {},
		normalized_entry_map = {},
		preview_delay_ms = args.preview_delay_ms or 0,
		popup = nil,
		promptbox = args.promptbox or wibox.widget.textbox(),
		active_entries = {},
		transaction = nil,
		closed = false,
		finished = false,
		preview_generation = 0,
	}

	if not args.promptbox then
		local prompt_screen = chooser.screen
		if prompt_screen and prompt_screen.mypromptbox and prompt_screen.mypromptbox.widget then
			chooser.promptbox = prompt_screen.mypromptbox.widget
		end
	end

	function chooser:invalidate_preview()
		self.preview_generation = self.preview_generation + 1
	end

	function chooser:get_current_entry()
		return self.active_entries[self.current_index]
	end

	function chooser:normalize_entries()
		local normalized = {}
		local normalized_entry_map = {}

		for _, entry in ipairs(self.entries) do
			local normalized_entry = normalize_entry(entry, self)
			normalized[#normalized + 1] = normalized_entry
			normalized_entry_map[entry] = normalized_entry
		end

		self.normalized_entries = normalized
		self.normalized_entry_map = normalized_entry_map
	end

	function chooser:ensure_popup()
		if self.popup then
			return self.popup
		end

		self.popup = build_popup({
			title = self.title,
			screen = self.screen,
			on_cancel = function()
				self:cancel()
			end,
		})

		return self.popup
	end

	function chooser:close_popup()
		self:invalidate_preview()

		if self.popup then
			self.popup:close()
			self.popup = nil
		end
	end

	function chooser:stop_prompt()
		if self.closed then
			return
		end

		self.closed = true
		awful.keygrabber.stop()
		self.promptbox:set_markup("")
	end

	function chooser:cleanup()
		self:stop_prompt()
		self:close_popup()
	end

	function chooser:rollback_transaction()
		if self.rollback then
			self.rollback(self.transaction, self)
		end
	end

	function chooser:snapshot_state()
		self.transaction = self.snapshot and self.snapshot(self) or nil
	end

	function chooser:rebuild(previous_entry)
		local filtered_entries = self.filter(self) or {}

		if filtered_entries == self.entries then
			self.active_entries = self.normalized_entries
		else
			local active_entries = {}

			for _, entry in ipairs(filtered_entries) do
				local normalized_entry = ensure_normalized_entry(entry, self)
				if normalized_entry then
					active_entries[#active_entries + 1] = normalized_entry
				end
			end

			self.active_entries = active_entries
		end

		if #self.active_entries == 0 then
			self.current_index = 1
			return
		end

		if previous_entry then
			for index, entry in ipairs(self.active_entries) do
				if entry == previous_entry then
					self.current_index = index
					return
				end
			end
		end

		if self.current_index < 1 or self.current_index > #self.active_entries then
			self.current_index = 1
		end
	end

	function chooser:update_popup()
		local items = {}

		for index, entry in ipairs(self.active_entries) do
			local item = normalize_rendered_item(
				(self.render and self.render(entry.raw, index == self.current_index, self))
					or { text = entry.text }
			)
			item.selected = index == self.current_index
			items[#items + 1] = item
		end

		self:ensure_popup():update({
			title = self.title,
			items = items,
		})
	end

	function chooser:run_preview(entry)
		if entry and self.preview then
			self.preview(entry.raw, self.transaction, self)
		end
	end

	function chooser:preview_current()
		local entry = self:get_current_entry()

		self:invalidate_preview()
		self:update_popup()

		if not entry or not self.preview then
			return
		end

		if self.preview_delay_ms <= 0 then
			self:run_preview(entry)
			return
		end

		local generation = self.preview_generation
		gears.timer({
			timeout = self.preview_delay_ms / 1000,
			autostart = true,
			single_shot = true,
			callback = function()
				if self.finished or self.closed then
					return
				end

				if generation == self.preview_generation and self:get_current_entry() == entry then
					self:run_preview(entry)
				end
			end,
		})
	end

	function chooser:apply_query(input)
		local previous_entry = self:get_current_entry()

		self.query = input or ""
		self:rebuild(previous_entry)
		self:preview_current()
	end

	function chooser:step(direction)
		if #self.active_entries == 0 then
			return
		end

		local count = #self.active_entries
		self.current_index = ((self.current_index - 1 + direction) % count) + 1
		self:preview_current()
	end

	function chooser:finish(action)
		if self.finished then
			return
		end

		self.finished = true
		local entry = self:get_current_entry()
		self:cleanup()

		if action == "commit" then
			if entry and self.commit then
				self.commit(entry.raw, self.transaction, self)
			end
			return
		end

		self:rollback_transaction()
	end

	function chooser:cancel()
		self:finish("cancel")
	end

	function chooser:confirm()
		self:finish("commit")
	end

	function chooser:handle_key(mod, key)
		for _, binding in ipairs(self.advance_keys) do
			if binding_matches(mod, key, binding) then
				self:step(binding.direction or 1)
				return true
			end
		end

		if key == "Up" or key == "Left" then
			self:step(-1)
			return true
		end

		if key == "Down" or key == "Right" then
			self:step(1)
			return true
		end

		if key == "Escape" then
			self:cancel()
			return false
		end

		return false
	end

	function chooser:start()
		self:normalize_entries()
		self:snapshot_state()
		self:rebuild()
		self:preview_current()

		awful.prompt.run({
			prompt = self.prompt,
			textbox = self.promptbox,
			hooks = build_prompt_hooks(),
			changed_callback = function(input)
				self:apply_query(input)
			end,
			keypressed_callback = function(mod, key)
				return self:handle_key(mod, key)
			end,
			exe_callback = function()
				self:confirm()
			end,
			done_callback = function()
				if not self.finished then
					self:cancel()
				end
			end,
		})
	end

	return chooser
end

function M.run(args)
	local chooser = M.new(args)
	chooser:start()
	return chooser
end

return M
