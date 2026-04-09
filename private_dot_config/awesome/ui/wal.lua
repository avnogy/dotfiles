local M = {}

local wal_cache_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/wal"
local preview_cache_dir = wal_cache_dir .. "/preview"
local palette_cache_dir = wal_cache_dir .. "/awesome-palettes"
local color_cache = {}

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

local function shell_quote(value)
	return "'" .. value:gsub("'", [['"'"']]) .. "'"
end

local function command_path(name)
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

local function cache_file_path(wallpaper, preview)
	local name = wallpaper:match("([^/]+)$") or wallpaper
	local prefix = preview and "preview-" or "full-"
	return palette_cache_dir .. "/" .. prefix .. name .. ".sh"
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

local function preview_wallpaper_path(wallpaper)
	local name = wallpaper:match("([^/]+)$") or "preview.png"
	local preview_path = preview_cache_dir .. "/" .. name
	local magick = command_path("magick")

	if read_file(preview_path) then
		return preview_path
	end

	if not magick then
		return wallpaper
	end

	os.execute("mkdir -p " .. shell_quote(preview_cache_dir))
	os.execute(
		shell_quote(magick)
			.. " "
			.. shell_quote(wallpaper)
			.. " -resize 512x512\\> "
			.. shell_quote(preview_path)
	)

	return read_file(preview_path) and preview_path or wallpaper
end

function M.apply(wallpaper, opts)
	local preview = opts and opts.preview
	local source_wallpaper = preview and preview_wallpaper_path(wallpaper) or wallpaper
	local wal = command_path("wal")

	if not wal then
		return false
	end

	local ok, _, code = os.execute(
		shell_quote(wal) .. " -q -n -i " .. shell_quote(source_wallpaper)
	)

	return ok == true or ok == 0 or code == 0
end

function M.colors(wallpaper, opts)
	local preview = opts and opts.preview
	local source_wallpaper = preview and preview_wallpaper_path(wallpaper) or wallpaper
	local cache_key = (preview and "preview:" or "full:") .. wallpaper
	local palette_cache_path = cache_file_path(wallpaper, preview)
	local current_wallpaper = read_file(wal_cache_dir .. "/wal")
	local colors_path = wal_cache_dir .. "/colors.sh"
	local wal = command_path("wal")

	if color_cache[cache_key] then
		return color_cache[cache_key]
	end

	local cached_content = read_file(palette_cache_path)
	if cached_content then
		color_cache[cache_key] = parse_colors(cached_content)
		return color_cache[cache_key]
	end

	if not wal then
		return {}
	end

	if current_wallpaper then
		current_wallpaper = current_wallpaper:gsub("^%s+", ""):gsub("%s+$", "")
	end

	if current_wallpaper ~= source_wallpaper or not read_file(colors_path) then
		if not M.apply(wallpaper, opts) then
			return {}
		end
	end

	local content = read_file(colors_path)
	if not content then
		return {}
	end

	os.execute("mkdir -p " .. shell_quote(palette_cache_dir))
	write_file(palette_cache_path, content)

	local colors = parse_colors(content)
	color_cache[cache_key] = colors
	return colors
end

return M
