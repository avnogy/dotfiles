local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

local popup_width = dpi(420)
local popup_padding = dpi(20)
local popup_spacing = dpi(16)
local row_height = dpi(24)
local header_height = dpi(18)

local function popup_height_for_rows(row_count)
    return (popup_padding * 2)
        + header_height
        + popup_spacing
        + (row_count * row_height)
end

local function build_row(text, selected)
    local content = wibox.widget {
        {
            text = text,
            widget = wibox.widget.textbox,
            font = beautiful.font,
            align = "left",
            valign = "center",
        },
        left = dpi(8),
        right = dpi(8),
        widget = wibox.container.margin,
    }

    if not selected then
        return content
    end

    return wibox.widget {
        {
            content,
            forced_height = row_height,
            widget = wibox.container.constraint,
        },
        bg = beautiful.bg_normal,
        border_width = beautiful.border_width,
        border_color = beautiful.border_focus,
        shape = gears.shape.rectangle,
        widget = wibox.container.background,
    }
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
        local backdrop = wibox {
            screen = s,
            visible = true,
            ontop = true,
            bg = "#00000000",
            x = s.geometry.x,
            y = s.geometry.y,
            width = s.geometry.width,
            height = s.geometry.height,
            widget = wibox.container.background(),
        }

        if buttons then
            backdrop:buttons(buttons)
        end

        backdrops[#backdrops + 1] = backdrop
    end

    return backdrops
end

function M.new(args)
    local target_screen = args.screen
    local rows = wibox.widget {
        spacing = dpi(6),
        layout = wibox.layout.fixed.vertical,
    }
    local title = wibox.widget {
        markup = "<b>" .. args.title .. "</b>",
        widget = wibox.widget.textbox,
        font = beautiful.font,
    }
    local backdrops = build_backdrops(args.on_cancel)

    local popup = awful.popup {
        screen = target_screen,
        visible = true,
        ontop = true,
        border_width = beautiful.border_width,
        border_color = beautiful.border_focus,
        bg = beautiful.bg_focus,
        fg = beautiful.fg_focus,
        minimum_width = popup_width,
        minimum_height = popup_height_for_rows(#args.rows),
        maximum_width = popup_width,
        maximum_height = popup_height_for_rows(#args.rows),
        placement = awful.placement.centered,
        widget = {
            {
                title,
                rows,
                spacing = popup_spacing,
                layout = wibox.layout.fixed.vertical,
            },
            margins = popup_padding,
            widget = wibox.container.margin,
        },
    }

    function popup:update(update_args)
        local new_rows = update_args.rows or {}
        local popup_height = popup_height_for_rows(#new_rows)

        title.markup = "<b>" .. (update_args.title or args.title) .. "</b>"
        rows:reset()

        for _, row in ipairs(new_rows) do
            rows:add(build_row(row.text, row.selected))
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

    popup:update(args)

    return popup
end

return M
