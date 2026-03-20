local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}
local chooser_width = dpi(420)
local chooser_padding = dpi(20)
local chooser_spacing = dpi(16)
local chooser_row_height = dpi(24)
local chooser_header_height = dpi(18)

M.available = {
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

awful.layout.layouts = M.available

local chooser_height = (chooser_padding * 2)
    + chooser_header_height
    + chooser_spacing
    + (#M.available * chooser_row_height)

local function snapshot_client(client)
    -- Layout preview can move windows around, so keep enough state to undo it on cancel.
    return {
        floating = client.floating,
        maximized = client.maximized,
        maximized_horizontal = client.maximized_horizontal,
        maximized_vertical = client.maximized_vertical,
        fullscreen = client.fullscreen,
        geometry = client:geometry(),
    }
end

local function restore_client(client, state)
    -- Restore flags first so geometry writes are not ignored by fullscreen/maximized states.
    client.floating = state.floating
    client.maximized = state.maximized
    client.maximized_horizontal = state.maximized_horizontal
    client.maximized_vertical = state.maximized_vertical
    client.fullscreen = state.fullscreen

    if not state.maximized and not state.maximized_horizontal
        and not state.maximized_vertical and not state.fullscreen then
        client:geometry(state.geometry)
    end
end

function M.choose()
    local screen = awful.screen.focused()
    local tag = screen.selected_tag
    if not tag then
        return
    end

    local original_layout = awful.layout.get(tag.screen)
    local current_index = 1
    local chooser_popup
    local chooser_rows
    local confirmed = false
    local query = ""
    local matches = {}
    local original_clients = {}

    for _, client in ipairs(tag:clients()) do
        original_clients[client] = snapshot_client(client)
    end

    for index, layout in ipairs(M.available) do
        if layout == original_layout then
            current_index = index
            break
        end
    end

    local function clear_notice()
        if chooser_popup then
            chooser_popup.visible = false
            chooser_popup = nil
            chooser_rows = nil
        end
    end

    local function ensure_popup()
        if chooser_popup then
            return
        end

        chooser_rows = wibox.widget {
            spacing = dpi(6),
            layout = wibox.layout.fixed.vertical,
        }

        chooser_popup = awful.popup {
            screen = screen,
            visible = true,
            ontop = true,
            border_width = beautiful.border_width,
            border_color = beautiful.border_focus,
            bg = beautiful.bg_focus,
            fg = beautiful.fg_focus,
            minimum_width = chooser_width,
            minimum_height = chooser_height,
            maximum_width = chooser_width,
            maximum_height = chooser_height,
            placement = awful.placement.centered,
            widget = {
                {
                    {
                        markup = "<b>Layout</b>",
                        widget = wibox.widget.textbox,
                        font = beautiful.font,
                    },
                    chooser_rows,
                    spacing = chooser_spacing,
                    layout = wibox.layout.fixed.vertical,
                },
                margins = chooser_padding,
                widget = wibox.container.margin,
            },
        }
    end

    local function rebuild_matches()
        local lowered = query:lower()
        matches = {}

        for index, layout in ipairs(M.available) do
            local name = awful.layout.getname(layout):lower()
            if lowered == ""
                or name == lowered
                or name:find("^" .. lowered, 1)
                or name:find(lowered, 1, true) then
                matches[#matches + 1] = index
            end
        end

        -- Keep arrow navigation working even when the typed filter has no matches.
        if #matches == 0 then
            for index = 1, #M.available do
                matches[#matches + 1] = index
            end
        end
    end

    local function current_match_position()
        for position, index in ipairs(matches) do
            if index == current_index then
                return position
            end
        end

        current_index = matches[1]
        return 1
    end

    local function show_current()
        ensure_popup()

        chooser_rows:reset()

        for i = 1, #matches do
            local index = matches[i]
            local selected = index == current_index
            local row = wibox.widget {
                {
                    text = (selected and "> " or "  ") .. awful.layout.getname(M.available[index]),
                    widget = wibox.widget.textbox,
                    font = beautiful.font,
                    align = "left",
                    valign = "center",
                },
                left = dpi(8),
                right = dpi(8),
                widget = wibox.container.margin,
            }

            if selected then
                row = wibox.widget {
                    {
                        row,
                        forced_height = chooser_row_height,
                        widget = wibox.container.constraint,
                    },
                    bg = beautiful.bg_normal,
                    border_width = beautiful.border_width,
                    border_color = beautiful.border_focus,
                    shape = gears.shape.rectangle,
                    widget = wibox.container.background,
                }
            end

            chooser_rows:add(row)
        end

        chooser_popup.screen = screen
        chooser_popup.visible = true
        awful.placement.centered(chooser_popup, { parent = screen })
    end

    local function preview_current()
        -- Preview is live: the selected tag changes immediately while the chooser is open.
        awful.layout.set(M.available[current_index], tag)
        show_current()
    end

    local function restore_original_state()
        -- Escape should restore both the original layout and the client placement it caused.
        awful.layout.set(original_layout, tag)

        for client, state in pairs(original_clients) do
            if client.valid then
                restore_client(client, state)
            end
        end
    end

    local function step_current(direction)
        local position = current_match_position() + direction
        if position < 1 then
            position = #matches
        elseif position > #matches then
            position = 1
        end

        current_index = matches[position]
        preview_current()
    end

    rebuild_matches()
    preview_current()

    awful.prompt.run {
        prompt = "Layout [Up/Down, Enter, Esc]: ",
        textbox = screen.mypromptbox.widget,
        changed_callback = function(input)
            -- Typing filters the list and previews the best remaining match.
            query = input or ""
            rebuild_matches()
            current_match_position()
            preview_current()
        end,
        keypressed_callback = function(_, key)
            if key == "Up" or key == "Left" then
                step_current(-1)
                return true
            end

            if key == "Down" or key == "Right" or key == "space" then
                step_current(1)
                return true
            end

            if key == "Escape" then
                restore_original_state()
                confirmed = true
                clear_notice()
                return false
            end

            return false
        end,
        exe_callback = function()
            confirmed = true
            clear_notice()
        end,
        done_callback = function()
            clear_notice()

            if not confirmed then
                restore_original_state()
            end
        end,
    }
end

return M
