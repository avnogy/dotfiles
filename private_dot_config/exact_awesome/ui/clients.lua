local awful = require("awful")
local popup_menu = require("ui.popup_menu")

local M = {}

local function snapshot_selected_tags()
	local screens = {}

	for s in screen do
		local selected_tags = {}

		for _, tag in ipairs(s.tags or {}) do
			if tag.selected then
				selected_tags[#selected_tags + 1] = tag
			end
		end

		screens[s] = selected_tags
	end

	return screens
end

local function restore_selected_tags(saved_tags_by_screen)
	for s, selected_tags in pairs(saved_tags_by_screen or {}) do
		if s.valid then
			local selected_lookup = {}

			for _, tag in ipairs(selected_tags) do
				if tag.valid then
					selected_lookup[tag] = true
				end
			end

			for _, tag in ipairs(s.tags or {}) do
				tag.selected = selected_lookup[tag] or false
			end
		end
	end
end

local function restore_focus_state(tx)
	if tx and tx.focused_screen and tx.focused_screen.valid then
		awful.screen.focus(tx.focused_screen)
	end

	if tx and tx.focused_client and tx.focused_client.valid then
		client.focus = tx.focused_client
		tx.focused_client:raise()
	end
end

local function preview_client(entry, tx)
	local selected_client = entry.client
	if not (selected_client and selected_client.valid) then
		return
	end

	restore_selected_tags(tx and tx.selected_tags_by_screen)

	local target_tag = selected_client.first_tag
	if target_tag and target_tag.valid then
		target_tag:view_only()

		if target_tag.screen and target_tag.screen.valid then
			awful.screen.focus(target_tag.screen)
		end
	else
		if tx and tx.focused_screen and tx.focused_screen.valid then
			awful.screen.focus(tx.focused_screen)
		end
	end

	selected_client:raise()
end

local function get_process_name(c)
	if not c.pid then
		return nil
	end

	local proc_comm = io.open(string.format("/proc/%d/comm", c.pid), "r")
	if not proc_comm then
		return nil
	end

	local process_name = proc_comm:read("*l")
	proc_comm:close()

	return process_name ~= "" and process_name or nil
end

function M.choose()
	local screen = awful.screen.focused()
	local entries = {}

	for _, c in ipairs(client.get()) do
		if c.valid then
			local process_name = get_process_name(c)
			local item_title = c.name or c.class or "Unknown"
			if #item_title > 40 then
				item_title = item_title:sub(1, 37) .. "..."
			end

			if process_name then
				item_title = string.format("%s: %s", process_name, item_title)
			end

			if c.first_tag and c.first_tag.name ~= "" then
				item_title = string.format("%s [%s]", item_title, c.first_tag.name)
			end

			entries[#entries + 1] = {
				client = c,
				title = item_title,
				match_text = ((process_name or "") .. "\n" .. (c.name or "") .. "\n" .. (c.class or "")):lower(),
			}
		end
	end

	if #entries == 0 then
		return
	end

	popup_menu.run {
		title = "Clients",
		screen = screen,
		promptbox = screen.mypromptbox.widget,
		advance_keys = {
			{ modifiers = { "Mod4" }, key = "Tab" },
		},
		entries = entries,
		text = function(entry)
			return entry.title
		end,
		snapshot = function()
			return {
				focused_screen = awful.screen.focused(),
				focused_client = client.focus,
				selected_tags_by_screen = snapshot_selected_tags(),
			}
		end,
		rollback = function(tx)
			restore_selected_tags(tx and tx.selected_tags_by_screen)
			restore_focus_state(tx)
		end,
		preview = preview_client,
		commit = function(entry)
			-- Jumping to a client delegates screen/tag selection to Awesome itself.
			if entry.client and entry.client.valid then
				entry.client:jump_to(false)
			end
		end,
	}
end

return M
