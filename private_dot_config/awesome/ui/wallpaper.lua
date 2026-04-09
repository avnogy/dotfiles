local gears = require("gears")
local gfs = require("gears.filesystem")
local awful = require("awful")
local popup_menu = require("ui.popup_menu")
local theme = require("ui.theme")

local M = {}

local config_dir = gfs.get_configuration_dir()
local wallpapers_dir = config_dir .. "wallpapers"
local optimized_dir = wallpapers_dir .. "/optimized"
local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/awesome"
local state_path = state_dir .. "/wallpaper"
local default_name = "wallhaven-eyz668_2560x1440.jpg"

local function file_text(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()
	return content
end

local function list_paths()
	local paths = {}
	local handle = io.popen("find '" .. optimized_dir:gsub("'", [['"'"']]) .. "' -maxdepth 1 -type f -name '*.jpg' | sort")
	if not handle then
		return paths
	end

	for path in handle:lines() do
		paths[#paths + 1] = path
	end

	handle:close()
	return paths
end

local function wallpaper_path(name)
	local filename = name and name:match("([^/]+)$") or default_name
	local path = optimized_dir .. "/" .. filename

	if gfs.file_readable(path) then
		return path
	end

	local default_path = optimized_dir .. "/" .. default_name
	if gfs.file_readable(default_path) then
		return default_path
	end

	return list_paths()[1]
end

function M.current()
	local current = file_text(state_path)

	if current then
		current = current:match("^%s*(.-)%s*$")
	end

	return wallpaper_path(current)
end

function M.apply(path, screen_obj)
	local beautiful = require("beautiful")
	local wallpaper = path and wallpaper_path(path) or M.current()

	beautiful.wallpaper = wallpaper

	if screen_obj then
		gears.wallpaper.maximized(wallpaper, screen_obj, true)
		return
	end

	for s in screen do
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

function M.apply_current(screen_obj)
	M.apply(nil, screen_obj)
end

function M.persist(path)
	local file = io.open(state_path, "w")

	os.execute("mkdir -p " .. "'" .. state_dir:gsub("'", [['"'"']]) .. "'")
	if not file then
		return false
	end

	file:write((path:match("([^/]+)$") or path) .. "\n")
	file:close()
	return true
end

function M.list()
	local entries = {}

	for _, path in ipairs(list_paths()) do
		entries[#entries + 1] = {
			name = path:match("([^/]+)$") or path,
			path = path,
		}
	end

	return entries
end

function M.choose()
	local screen = awful.screen.focused()
	local entries = M.list()
	local current_path = M.current()
	local current_index = 1

	if #entries == 0 then
		return
	end

	for index, entry in ipairs(entries) do
		if entry.path == current_path then
			current_index = index
			break
		end
	end

	popup_menu.run({
		title = "Wallpaper",
		screen = screen,
		promptbox = screen.mypromptbox.widget,
		advance_keys = {
			{ modifiers = { "Mod4", "Shift" }, key = "t" },
		},
		entries = entries,
		preview_delay_ms = 100,
		text = function(entry)
			return entry.name
		end,
		current_index = current_index,
		snapshot = function()
			return current_path
		end,
		rollback = function(original_path)
			if original_path then
				theme.apply(original_path)
			end
		end,
		preview = function(entry)
			theme.apply(entry.path, { preview = true })
		end,
		commit = function(entry)
			M.persist(entry.path)
			theme.apply(entry.path)
		end,
	})
end

return M
