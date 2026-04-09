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

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()
	return content
end

local function write_file(path, content)
	local file = io.open(path, "w")
	if not file then
		return false
	end

	file:write(content)
	file:close()
	return true
end

local function trim(value)
	if not value then
		return nil
	end

	return value:gsub("^%s+", ""):gsub("%s+$", "")
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

local function resolve_path(value)
	if value and gfs.file_readable(value) then
		return value
	end

	local name = value and value:match("([^/]+)$") or default_name
	local path = optimized_dir .. "/" .. name
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
	return resolve_path(trim(read_file(state_path)))
end

function M.apply(path, screen_obj)
	local beautiful = require("beautiful")
	local wallpaper = resolve_path(path or M.current())

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
	os.execute("mkdir -p " .. "'" .. state_dir:gsub("'", [['"'"']]) .. "'")
	return write_file(state_path, (path:match("([^/]+)$") or path) .. "\n")
end

function M.list()
	local entries = {}
	for _, path in ipairs(list_paths()) do
		local name = path:match("([^/]+)$") or path
		entries[#entries + 1] = {
			name = name,
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
		preview_delay_ms = 150,
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
