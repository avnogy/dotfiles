local M = {}

local wal_cache_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/wal"
local palette_cache_dir = wal_cache_dir .. "/awesome-palettes"
local color_cache = {}

local function file_text(path)
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

local function command(name)
	local home = os.getenv("HOME")
	local candidates = {
		home and (home .. "/.local/bin/" .. name) or nil,
		"/usr/local/bin/" .. name,
		"/usr/bin/" .. name,
		"/bin/" .. name,
	}

	for _, candidate in ipairs(candidates) do
		local handle = candidate and io.open(candidate, "r") or nil
		if handle then
			handle:close()
			return candidate
		end
	end

	local handle = io.popen("command -v " .. name .. " 2>/dev/null")
	if not handle then
		return nil
	end

	local path = handle:read("*l")
	handle:close()
	return path and path ~= "" and path or nil
end

local function cache_file_path(path)
	local name = path:match("([^/]+)$") or path
	return palette_cache_dir .. "/full-" .. name .. ".sh"
end

local function parse_colors(content)
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

function M.apply(wallpaper)
	local wal = command("wal")

	if not wal then
		return false
	end

	local ok, _, code = os.execute(shell_quote(wal) .. " -q -n -i " .. shell_quote(wallpaper) .. " --saturate 0.1 --backend colorthief")

	return ok == true or ok == 0 or code == 0
end

function M.colors(wallpaper)
	local cache_key = wallpaper
	local palette_cache_path = cache_file_path(wallpaper)
	local current_wallpaper = file_text(wal_cache_dir .. "/wal")
	local colors_path = wal_cache_dir .. "/colors.sh"

	if color_cache[cache_key] then
		return color_cache[cache_key]
	end

	local cached_content = file_text(palette_cache_path)
	if cached_content then
		color_cache[cache_key] = parse_colors(cached_content)
		return color_cache[cache_key]
	end

	if current_wallpaper then
		current_wallpaper = current_wallpaper:gsub("^%s+", ""):gsub("%s+$", "")
	end

	if current_wallpaper ~= wallpaper or not file_text(colors_path) then
		if not M.apply(wallpaper) then
			return {}
		end
	end

	local content = file_text(colors_path)
	if not content then
		return {}
	end

	os.execute("mkdir -p " .. shell_quote(palette_cache_dir))
	local file = io.open(palette_cache_path, "w")
	if file then
		file:write(content)
		file:close()
	end

	local colors = parse_colors(content)
	color_cache[cache_key] = colors
	return colors
end

return M
