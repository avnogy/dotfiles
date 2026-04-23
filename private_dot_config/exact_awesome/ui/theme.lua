local beautiful = require("beautiful")
local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local xrdb = xresources.get_current_theme()

local gears = require("gears")
local gfs = require("gears.filesystem")
local wal = require("ui.wal")
local themes_path = gfs.get_themes_dir()

local M = {}

function M.build(wallpaper_path)
	if not wallpaper_path then
		wallpaper_path = require("ui.wallpaper").current()
	end

	local theme = dofile(themes_path .. "default/theme.lua")
	local colors = wal.colors(wallpaper_path)
	local base_bg = colors.background or xrdb.background or "#1a1a1a"
	local base_fg = colors.foreground or xrdb.foreground or "#d0d0d0"
	local accent = colors.color4 or colors.color12 or xrdb.color4 or xrdb.color12 or "#5f87ff"
	local accent_alt = colors.color6 or colors.color14 or xrdb.color6 or xrdb.color14 or accent
	local urgent = colors.color1 or colors.color9 or xrdb.color1 or xrdb.color9 or "#cc5555"
	local surface = colors.color0 or xrdb.color0 or "#111111"
	local surface_alt = colors.color8 or xrdb.color8 or "#222222"

	theme.font = "monospace 8"

	theme.bg_normal = base_bg
	theme.bg_focus = surface
	theme.bg_urgent = surface
	theme.bg_minimize = surface
	theme.bg_systray = theme.bg_normal

	theme.fg_normal = base_fg
	theme.fg_focus = base_fg
	theme.fg_urgent = base_fg
	theme.fg_minimize = base_fg

	theme.useless_gap = dpi(4)
	theme.border_width = dpi(1)
	theme.border_normal = surface
	theme.border_focus = accent
	theme.border_marked = accent_alt

	theme.menu_bg_normal = theme.bg_normal
	theme.menu_fg_normal = theme.fg_normal
	theme.menu_bg_focus = theme.bg_focus
	theme.menu_fg_focus = theme.fg_focus

	theme.taglist_bg_focus = theme.tasklist_bg_focus
	theme.taglist_fg_focus = theme.tasklist_fg_focus
	theme.taglist_bg_occupied = surface
	theme.taglist_fg_occupied = surface_alt
	theme.taglist_bg_empty = base_bg
	theme.taglist_fg_empty = surface_alt
	theme.taglist_bg_urgent = surface
	theme.taglist_fg_urgent = urgent

	theme.tasklist_bg_focus = surface
	theme.tasklist_fg_focus = accent
	theme.tasklist_bg_normal = theme.bg_normal
	theme.tasklist_fg_normal = theme.fg_normal
	theme.tasklist_bg_urgent = theme.bg_urgent
	theme.tasklist_fg_urgent = theme.fg_urgent

	theme.titlebar_bg_normal = theme.bg_normal
	theme.titlebar_fg_normal = theme.fg_normal
	theme.titlebar_bg_focus = theme.bg_focus
	theme.titlebar_fg_focus = base_fg

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

	theme.popup_menu_bg = base_bg
	theme.popup_menu_fg = base_fg
	theme.popup_menu_border = surface_alt
	theme.popup_menu_item_bg = surface_alt
	theme.popup_menu_item_border = accent
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
	theme = theme_assets.recolor_titlebar(theme, theme.fg_normal, "normal", "hover")
	theme = theme_assets.recolor_titlebar(theme, urgent, "normal", "press")
	theme = theme_assets.recolor_titlebar(theme, theme.fg_focus, "focus")
	theme = theme_assets.recolor_titlebar(theme, theme.fg_focus, "focus", "hover")
	theme = theme_assets.recolor_titlebar(theme, accent, "focus", "press")

	theme.wallpaper = wallpaper_path

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
	theme.taglist_fg_focus = base_fg
	theme.icon_theme = nil

	return theme
end

local function refresh_ui()
	for s in screen do
		if s.selected_tag then
			s.selected_tag:emit_signal("property::selected")
		end

		s:emit_signal("tag::history::update")

		if s.mytaglist then
			s.mytaglist:emit_signal("widget::redraw_needed")
			s.mytaglist:emit_signal("widget::layout_changed")
		end

		if s.mytasklist then
			s.mytasklist:emit_signal("widget::redraw_needed")
			s.mytasklist:emit_signal("widget::layout_changed")
		end

		if s.mywibox then
			s.mywibox:emit_signal("widget::redraw_needed")
			s.mywibox:emit_signal("widget::layout_changed")
		end
	end

	for _, c in ipairs(client.get()) do
		c.border_color = c == client.focus and beautiful.border_focus or beautiful.border_normal
		c:emit_signal("property::name")
	end
end

function M.apply(wallpaper_path)
	wallpaper_path = wallpaper_path or require("ui.wallpaper").current()
	wal.apply(wallpaper_path)
	beautiful.init(M.build(wallpaper_path))
	require("ui.wallpaper").apply(wallpaper_path)
	refresh_ui()
	gears.timer.delayed_call(function()
		awesome.emit_signal("theme::reload")
	end)
end

return M
