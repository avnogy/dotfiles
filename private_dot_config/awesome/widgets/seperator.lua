local wibox = require("wibox")

local separator = wibox.widget {
    {
        id     = "txt",
        widget = wibox.widget.textbox,
        text   = "|",
        align  = "center",
        valign = "center",
    },
    layout        = wibox.container.place,
    -- forced_width  = 12,
    forced_height = 20,
}

return separator
