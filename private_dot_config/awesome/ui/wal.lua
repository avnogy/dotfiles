local M = {}

local wal_cache_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/wal"

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()
	return content
end

local function shell_quote(value)
	return "'" .. value:gsub("'", [['"'"']]) .. "'"
end

function M.colors(wallpaper)
	local current_wallpaper = read_file(wal_cache_dir .. "/wal")
	local colors_path = wal_cache_dir .. "/colors.sh"

	if current_wallpaper then
		current_wallpaper = current_wallpaper:gsub("^%s+", ""):gsub("%s+$", "")
	end

	if current_wallpaper ~= wallpaper or not read_file(colors_path) then
		local ok, _, code = os.execute("wal -q -n -i " .. shell_quote(wallpaper))
		if ok ~= true and ok ~= 0 and code ~= 0 then
			return {}
		end
	end

	local content = read_file(colors_path)
	if not content then
		return {}
	end

	local colors = {
		background = content:match("background='([^']+)'"),
		foreground = content:match("foreground='([^']+)'"),
		cursor = content:match("cursor='([^']+)'"),
	}

	for i = 0, 15 do
		colors["color" .. i] = content:match("color" .. i .. "='([^']+)'")
	end

	return colors
end

return M
