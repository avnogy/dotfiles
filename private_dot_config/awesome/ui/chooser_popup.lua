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

local function build_row(text, selected)
    local row = wibox.widget {
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
        return row
    end

    return wibox.widget {
        {
            row,
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

function M.new(args)
    local screen = args.screen
    local popup_height = (popup_padding * 2)
        + header_height
        + popup_spacing
        + (#args.rows * row_height)
    local rows = wibox.widget {
        spacing = dpi(6),
        layout = wibox.layout.fixed.vertical,
    }

    for _, row in ipairs(args.rows) do
        rows:add(build_row(row.text, row.selected))
    end

    return awful.popup {
        screen = screen,
        visible = true,
        ontop = true,
        border_width = beautiful.border_width,
        border_color = beautiful.border_focus,
        bg = beautiful.bg_focus,
        fg = beautiful.fg_focus,
        minimum_width = popup_width,
        minimum_height = popup_height,
        maximum_width = popup_width,
        maximum_height = popup_height,
        placement = awful.placement.centered,
        widget = {
            {
                {
                    markup = "<b>" .. args.title .. "</b>",
                    widget = wibox.widget.textbox,
                    font = beautiful.font,
                },
                rows,
                spacing = popup_spacing,
                layout = wibox.layout.fixed.vertical,
            },
            margins = popup_padding,
            widget = wibox.container.margin,
        },
    }
end

return M
