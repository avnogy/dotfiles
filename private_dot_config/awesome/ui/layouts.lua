local awful = require("awful")
local chooser_popup = require("ui.chooser_popup")

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
    local popup
    local confirmed = false
    local query = ""
    local matches = {}
    local original_clients = {}
    local original_focus = client.focus
    local cancel_chooser

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
        if popup then
            popup:close()
            popup = nil
        end
    end

    local function stop_prompt()
        awful.keygrabber.stop()
        screen.mypromptbox.widget:set_markup("")
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

    local function show_current()
        local rows = {}

        for i = 1, #matches do
            local index = matches[i]
            rows[#rows + 1] = {
                text = (index == current_index and "> " or "  ") .. awful.layout.getname(M.available[index]),
                selected = index == current_index,
            }
        end

        if popup then
            popup:update {
                title = "Layout",
                rows = rows,
            }
            return
        end

        popup = chooser_popup.new {
            title = "Layout",
            screen = screen,
            rows = rows,
            on_cancel = cancel_chooser,
        }
    end

    local function restore_focus()
        if original_focus and original_focus.valid then
            client.focus = original_focus
            original_focus:raise()
        end
    end

    local function preview_current()
        -- Preview is live: the selected tag changes immediately while the chooser is open.
        awful.layout.set(M.available[current_index], tag)
        restore_focus()
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

        restore_focus()
    end

    cancel_chooser = function()
        if confirmed then
            return
        end

        confirmed = true
        stop_prompt()
        restore_original_state()
        clear_notice()
    end

    local function step_current(direction)
        local position = 1

        for i, index in ipairs(matches) do
            if index == current_index then
                position = i
                break
            end
        end

        position = position + direction
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
            local found = false

            query = input or ""
            rebuild_matches()

            for _, index in ipairs(matches) do
                if index == current_index then
                    found = true
                    break
                end
            end

            if not found then
                current_index = matches[1]
            end

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
            restore_focus()
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
