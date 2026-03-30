local awful = require("awful")
local popup_menu = require("ui.popup_menu")

local M = {}

function M.choose()
    local screen = awful.screen.focused()

    popup_menu.run {
        title = "System",
        screen = screen,
        promptbox = screen.mypromptbox.widget,
        advance_keys = {
            { modifiers = { "Mod4", "Shift" }, key = "BackSpace" },
        },
        entries = {
            {
                text = "lock",
                action = function()
                    awful.spawn.with_shell("slock > /dev/null 2>&1 &")
                end,
            },
            {
                text = "display off",
                action = function()
                    awful.spawn({ "xset", "dpms", "force", "standby" })
                end,
            },
            {
                text = "shutdown",
                action = function()
                    awful.spawn({ "systemctl", "poweroff", "-i" })
                end,
            },
            {
                text = "reboot",
                action = function()
                    awful.spawn({ "systemctl", "reboot", "-i" })
                end,
            },
            {
                text = "leave awesome",
                action = function()
                    awesome.quit()
                end,
            },
            {
                text = "hibernate",
                action = function()
                    awful.spawn.with_shell("slock && systemctl hibernate -i")
                end,
            },
            {
                text = "sleep",
                action = function()
                    awful.spawn.with_shell("slock && systemctl suspend -i")
                end,
            },
        },
        commit = function(entry)
            entry.action()
        end,
    }
end

return M
