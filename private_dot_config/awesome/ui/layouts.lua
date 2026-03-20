local awful = require("awful")
local naughty = require("naughty")

local M = {}

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
    local chooser_notice
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
        if chooser_notice then
            naughty.destroy(chooser_notice)
            chooser_notice = nil
        end
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
        clear_notice()

        -- Show a short window into the current match list rather than the whole layout list.
        local lines = {}
        for i = 1, math.min(#matches, 8) do
            local index = matches[i]
            local prefix = index == current_index and "> " or "  "
            lines[#lines + 1] = prefix .. awful.layout.getname(M.available[index])
        end

        chooser_notice = naughty.notify {
            title = "Layout",
            text = table.concat(lines, "\n"),
            timeout = 0,
        }
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
