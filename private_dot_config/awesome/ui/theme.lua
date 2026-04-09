local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local xrdb = xresources.get_current_theme()

local gfs = require("gears.filesystem")
local wal = require("ui.wal")
local themes_path = gfs.get_themes_dir()
local config_dir = gfs.get_configuration_dir()
local wallpaper = config_dir .. "wallpapers/wallhaven-eyz668_2560x1440.png"

local theme = dofile(themes_path .. "default/theme.lua")

local function shift_color(color_value, amount)
	local result = "#"
	for pair in color_value:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
		local value = tonumber("0x" .. pair) + amount
		if value < 0 then
			value = 0
		end
		if value > 255 then
			value = 255
		end
		result = result .. string.format("%2.2x", value)
	end
	return result
end

local function blend_colors(first, second, ratio)
	local result = "#"
	local left_pairs = {}
	local right_pairs = {}

	for pair in first:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
		left_pairs[#left_pairs + 1] = pair
	end

	for pair in second:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
		right_pairs[#right_pairs + 1] = pair
	end

	for i = 1, math.min(#left_pairs, #right_pairs) do
		local left = tonumber("0x" .. left_pairs[i])
		local right = tonumber("0x" .. right_pairs[i])
		local value = math.floor((left * (1 - ratio)) + (right * ratio) + 0.5)
		result = result .. string.format("%2.2x", value)
	end

	return result
end

local colors = wal.colors(wallpaper)
local base_bg = colors.background or xrdb.background or "#1a1a1a"
local base_fg = colors.foreground or xrdb.foreground or "#d0d0d0"
local accent = colors.color4 or colors.color12 or xrdb.color4 or xrdb.color12 or "#5f87ff"
local accent_alt = colors.color6 or colors.color14 or xrdb.color6 or xrdb.color14 or accent
local urgent = colors.color1 or colors.color9 or xrdb.color1 or xrdb.color9 or "#cc5555"
local surface = colors.color0 or xrdb.color0 or shift_color(base_bg, 16)
local surface_alt = colors.color8 or xrdb.color8 or shift_color(surface, 24)
local muted_focus_fg = blend_colors(base_fg, accent, 0.1)
local tag_focus_fg = blend_colors(base_fg, accent, 0.22)
local titlebar_focus_fg = blend_colors(base_fg, accent_alt, 0.18)

theme.font = "JetBrains Mono NL 8"

theme.bg_normal = base_bg
theme.bg_focus = blend_colors(surface_alt, accent, 0.15)
theme.bg_urgent = blend_colors(surface, urgent, 0.2)
theme.bg_minimize = surface
theme.bg_systray = theme.bg_normal

theme.fg_normal = base_fg
theme.fg_focus = muted_focus_fg
theme.fg_urgent = base_fg
theme.fg_minimize = shift_color(base_fg, -24)

theme.useless_gap = dpi(4)
theme.border_width = dpi(1)
theme.border_normal = surface
theme.border_focus = accent
theme.border_marked = accent_alt

theme.menu_bg_normal = theme.bg_normal
theme.menu_fg_normal = theme.fg_normal
theme.menu_bg_focus = theme.bg_focus
theme.menu_fg_focus = theme.fg_focus

theme.taglist_bg_focus = theme.bg_focus
theme.taglist_fg_focus = theme.fg_focus
theme.taglist_bg_occupied = theme.bg_normal
theme.taglist_fg_occupied = theme.fg_normal
theme.taglist_bg_empty = theme.bg_normal
theme.taglist_fg_empty = theme.fg_minimize
theme.taglist_bg_urgent = theme.bg_urgent
theme.taglist_fg_urgent = theme.fg_urgent

theme.tasklist_bg_focus = theme.bg_focus
theme.tasklist_fg_focus = muted_focus_fg
theme.tasklist_bg_normal = theme.bg_normal
theme.tasklist_fg_normal = theme.fg_normal
theme.tasklist_bg_urgent = theme.bg_urgent
theme.tasklist_fg_urgent = theme.fg_urgent

theme.titlebar_bg_normal = theme.bg_normal
theme.titlebar_fg_normal = theme.fg_normal
theme.titlebar_bg_focus = theme.bg_focus
theme.titlebar_fg_focus = titlebar_focus_fg

theme.tooltip_fg = theme.fg_normal
theme.tooltip_bg = surface
theme.tooltip_border_width = theme.border_width
theme.tooltip_border_color = theme.border_focus

local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(taglist_square_size, theme.fg_normal)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(taglist_square_size, theme.fg_normal)

theme.menu_submenu_icon = themes_path .. "default/submenu.png"
theme.menu_height = dpi(15)
theme.menu_width = dpi(100)

theme.popup_menu_bg = blend_colors(base_bg, surface, 0.65)
theme.popup_menu_fg = base_fg
theme.popup_menu_border = blend_colors(surface_alt, accent, 0.35)
theme.popup_menu_item_bg = blend_colors(surface_alt, accent, 0.18)
theme.popup_menu_item_border = blend_colors(surface_alt, accent, 0.45)
theme.popup_menu_width = dpi(420)
theme.popup_menu_padding = dpi(20)
theme.popup_menu_spacing = dpi(16)
theme.popup_menu_item_spacing = dpi(6)
theme.popup_menu_item_height = dpi(24)
theme.popup_menu_header_height = dpi(18)
theme.popup_menu_item_padding = dpi(8)
theme.popup_menu_backdrop_bg = "#00000000"

theme = theme_assets.recolor_layout(theme, theme.fg_normal)

theme = theme_assets.recolor_titlebar(theme, theme.fg_normal, "normal")
theme = theme_assets.recolor_titlebar(theme, shift_color(theme.fg_normal, 60), "normal", "hover")
theme = theme_assets.recolor_titlebar(theme, urgent, "normal", "press")
theme = theme_assets.recolor_titlebar(theme, theme.fg_focus, "focus")
theme = theme_assets.recolor_titlebar(theme, shift_color(theme.fg_focus, 60), "focus", "hover")
theme = theme_assets.recolor_titlebar(theme, shift_color(accent, 24), "focus", "press")

theme.wallpaper = wallpaper

theme.layout_fairh = themes_path .. "default/layouts/fairhw.png"
theme.layout_fairv = themes_path .. "default/layouts/fairvw.png"
theme.layout_floating = themes_path .. "default/layouts/floatingw.png"
theme.layout_magnifier = themes_path .. "default/layouts/magnifierw.png"
theme.layout_max = themes_path .. "default/layouts/maxw.png"
theme.layout_fullscreen = themes_path .. "default/layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path .. "default/layouts/tilebottomw.png"
theme.layout_tileleft = themes_path .. "default/layouts/tileleftw.png"
theme.layout_tile = themes_path .. "default/layouts/tilew.png"
theme.layout_tiletop = themes_path .. "default/layouts/tiletopw.png"
theme.layout_spiral = themes_path .. "default/layouts/spiralw.png"
theme.layout_dwindle = themes_path .. "default/layouts/dwindlew.png"
theme.layout_cornernw = themes_path .. "default/layouts/cornernww.png"
theme.layout_cornerne = themes_path .. "default/layouts/cornernew.png"
theme.layout_cornersw = themes_path .. "default/layouts/cornersww.png"
theme.layout_cornerse = themes_path .. "default/layouts/cornersew.png"

theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, theme.border_focus, theme.fg_focus)
theme.tasklist_disable_icon = true
theme.taglist_fg_focus = tag_focus_fg

theme.icon_theme = nil

return theme
