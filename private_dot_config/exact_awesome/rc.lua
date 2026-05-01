pcall(require, "luarocks.loader")
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local theme = require("ui.theme")

require("error_handling.handle_startup_error")
require("error_handling.handle_runtime_error")

require("startx")

beautiful.init(theme.build())

require("ui.layouts")
require("ui.bar")

local globalkeys = require("bindings.globalkeys")
root.keys(globalkeys)
awful.rules.rules = require("rules")
require("signals.client")
