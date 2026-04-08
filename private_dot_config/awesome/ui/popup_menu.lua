local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local M = {}

local popup_width = beautiful.popup_menu_width
local popup_padding = beautiful.popup_menu_padding
local popup_spacing = beautiful.popup_menu_spacing
local item_spacing = beautiful.popup_menu_item_spacing
local item_height = beautiful.popup_menu_item_height
local header_height = beautiful.popup_menu_header_height
local item_padding = beautiful.popup_menu_item_padding

local function popup_height_for_items(item_count)
	return (popup_padding * 2) + header_height + popup_spacing + (item_count * item_height)
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
		left = item_padding,
		right = item_padding,
		widget = wibox.container.margin,
	})

	if not item.selected then
		return content
	end

	return wibox.widget({
		{
			content,
			forced_height = item_height,
			widget = wibox.container.constraint,
		},
		bg = beautiful.bg_normal,
		border_width = beautiful.border_width,
		border_color = beautiful.border_focus,
		shape = gears.shape.rectangle,
		widget = wibox.container.background,
	})
end

-- Build one transparent fullscreen backdrop per screen so outside clicks
-- cancel the chooser even when the popup itself is shown on only one screen.
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
	local items_widget = wibox.widget({
		spacing = item_spacing,
		layout = wibox.layout.fixed.vertical,
	})
	local title_widget = wibox.widget({
		markup = "<b>" .. args.title .. "</b>",
		widget = wibox.widget.textbox,
		font = beautiful.font,
	})
	local backdrops = build_backdrops(args.on_cancel)

	local popup = awful.popup({
		screen = args.screen,
		visible = true,
		ontop = true,
		border_width = beautiful.border_width,
		border_color = beautiful.border_focus,
		bg = beautiful.bg_focus,
		fg = beautiful.fg_focus,
		minimum_width = popup_width,
		minimum_height = popup_height_for_items(0),
		maximum_width = popup_width,
		maximum_height = popup_height_for_items(0),
		placement = awful.placement.centered,
		widget = {
			{
				title_widget,
				items_widget,
				spacing = popup_spacing,
				layout = wibox.layout.fixed.vertical,
			},
			margins = popup_padding,
			widget = wibox.container.margin,
		},
	})

	function popup:update(update_args)
		local items = update_args.items or {}
		local popup_height = popup_height_for_items(#items)

		title_widget.markup = "<b>" .. update_args.title .. "</b>"
		items_widget:reset()

		for _, item in ipairs(items) do
			items_widget:add(build_item(item))
		end

		self.minimum_height = popup_height
		self.maximum_height = popup_height
	end

	function popup:close()
		self.visible = false
		for _, backdrop in ipairs(backdrops) do
			backdrop.visible = false
		end
	end

	return popup
end

local function default_match(entry, query)
	-- Default filtering matches against the entry's text field.
	local text = entry._popup_menu_match_text or entry.match_text
	local lowered = query:lower()

	if not text then
		text = (entry._popup_menu_text or entry.text or ""):lower()
		entry._popup_menu_match_text = text
	end

	return lowered == "" or text == lowered or text:find("^" .. lowered, 1) or text:find(lowered, 1, true)
end

local function normalize_rendered_item(rendered)
	if type(rendered) == "string" then
		return { text = rendered }
	end

	return rendered
end

local function key_matches(binding_key, key)
	if binding_key == key then
		return true
	end

	return binding_key == "space" and key == " "
end

local function binding_matches(mod, key, binding)
	local modifiers = binding.modifiers or {}

	if not key_matches(binding.key, key) then
		return false
	end

	for _, modifier in ipairs(modifiers) do
		if not mod[modifier] then
			return false
		end
	end

	return true
end

local function default_recalculate(ctx)
	-- Rebuild the visible entry list from the current query.
	local entries = {}

	for _, entry in ipairs(ctx.entries) do
		if ctx.matcher(entry, ctx.query, ctx) then
			entries[#entries + 1] = entry
		end
	end

	if #entries == 0 and ctx.fallback_to_all then
		return ctx.entries
	end

	return entries
end

function M.new(args)
	-- Generic chooser controller.
	--
	-- Public hooks:
	--   snapshot(ctx) -> tx
	--   rollback(tx, ctx)
	--   preview(entry, tx, ctx)
	--   commit(entry, tx, ctx)
	--   recalculate(ctx) -> entries
	--   render(entry, selected, ctx) -> { text = ... } | string
	local chooser = {
		screen = args.screen or awful.screen.focused(),
		title = args.title,
		prompt = (args.prompt_title or args.title) .. ": ",
		advance_keys = args.advance_keys or {},
		query = args.query or "",
		current_index = args.current_index or 1,
		fallback_to_all = args.fallback_to_all ~= false,
		text = args.text or function(entry)
			return entry.text or ""
		end,
		render = args.render,
		matcher = args.matcher or default_match,
		recalculate = args.recalculate or default_recalculate,
		preview = args.preview,
		snapshot_callback = args.snapshot,
		commit = args.commit,
		rollback = args.rollback,
		entries = args.entries or {},
		popup = nil,
		promptbox = args.promptbox or (args.screen or awful.screen.focused()).mypromptbox.widget,
		active_entries = {},
		transaction = nil,
		confirmed = false,
	}

	function chooser:close()
		if self.popup then
			self.popup:close()
			self.popup = nil
		end
	end

	function chooser:stop()
		awful.keygrabber.stop()
		self.promptbox:set_markup("")
	end

	function chooser:update_popup()
		-- Render the current active entries into the popup view.
		local items = {}

		for index, entry in ipairs(self.active_entries) do
			local item = normalize_rendered_item(
				(self.render and self.render(entry, index == self.current_index, self))
					or { text = entry._popup_menu_text or entry.text or "" }
			)
			item.selected = index == self.current_index
			items[#items + 1] = item
		end

		if not self.popup then
			self.popup = build_popup({
				title = self.title,
				screen = self.screen,
				on_cancel = function()
					self:cancel_current()
				end,
			})
		end

		self.popup:update({
			title = self.title,
			items = items,
		})
	end

	function chooser:snapshot_state()
		-- Capture any state needed to roll back preview side effects on cancel.
		self.transaction = self.snapshot_callback and self.snapshot_callback(self) or nil
	end

	function chooser:rollback_transaction()
		if self.rollback then
			self.rollback(self.transaction, self)
		end
	end

	function chooser:get_current_entry()
		return self.active_entries[self.current_index]
	end

	function chooser:rebuild()
		-- Recalculate visible entries and clamp the current selection.
		for _, entry in ipairs(self.entries) do
			entry._popup_menu_text = entry._popup_menu_text or self.text(entry, self)
		end

		self.active_entries = self.recalculate(self) or {}
		if #self.active_entries == 0 then
			self.current_index = 1
		elseif self.current_index < 1 then
			self.current_index = #self.active_entries
		elseif self.current_index > #self.active_entries then
			self.current_index = 1
		end
	end

	function chooser:preview_current()
		-- Preview is optional; chooser types like layouts use it for live updates.
		local entry = self:get_current_entry()

		if entry and self.preview then
			self.preview(entry, self.transaction, self)
		end

		self:update_popup()
	end

	function chooser:sync_after_query_change()
		-- Keep the same entry selected after filtering when it still exists.
		local previous = self:get_current_entry()

		self:rebuild()
		if previous and #self.active_entries > 0 then
			for index, entry in ipairs(self.active_entries) do
				if entry == previous then
					self.current_index = index
					return
				end
			end
		end

		self.current_index = 1
	end

	function chooser:step(direction)
		if #self.active_entries == 0 then
			return
		end

		self.current_index = self.current_index + direction

		if self.current_index < 1 then
			self.current_index = #self.active_entries
		elseif self.current_index > #self.active_entries then
			self.current_index = 1
		end

		self:preview_current()
	end

	function chooser:cancel_current()
		if self.confirmed then
			return
		end

		self.confirmed = true
		self:stop()
		self:close()
		self:rollback_transaction()
	end

	function chooser:confirm_current()
		if self.confirmed then
			return
		end

		self.confirmed = true
		self:close()

		local entry = self:get_current_entry()
		if entry and self.commit then
			self.commit(entry, self.transaction, self)
		end
	end

	function chooser:start()
		-- Prompt lifecycle:
		--   snapshot -> initial rebuild/preview -> prompt loop -> commit or rollback
		self:snapshot_state()
		self:rebuild()
		self:preview_current()

		local hooks = {
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

		awful.prompt.run({
			prompt = self.prompt,
			textbox = self.promptbox,
			hooks = hooks,
			changed_callback = function(input)
				self.query = input or ""
				self:sync_after_query_change()
				self:preview_current()
			end,
			keypressed_callback = function(mod, key)
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
					self:cancel_current()
					return false
				end

				return false
			end,
			exe_callback = function()
				self:confirm_current()
			end,
			done_callback = function()
				self:close()

				if not self.confirmed then
					self:rollback_transaction()
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
