local awful = require("awful")
local chooser_popup = require("ui.chooser_popup")

local M = {}

function M.choose()
    local screen = awful.screen.focused()
    local tag = screen.selected_tag
    if not tag then
        return
    end

    local clients = {}
    for _, c in ipairs(screen.clients) do
        if not c.hidden and not c.minimized then
            clients[#clients + 1] = c
        end
    end

    if #clients == 0 then
        return
    end

    local original_focus = client.focus
    local current_index = 1
    local popup
    local confirmed = false
    local query = ""
    local matches = {}

    local function clear_notice()
        if popup then
            popup.visible = false
            popup = nil
        end
    end

    local function rebuild_matches()
        local lowered = query:lower()
        matches = {}

        for i, c in ipairs(clients) do
            local title = (c.name or ""):lower()
            local class = (c.class or ""):lower()
            if lowered == ""
                or title == lowered
                or title:find("^" .. lowered, 1)
                or title:find(lowered, 1)
                or class == lowered
                or class:find("^" .. lowered, 1)
                or class:find(lowered, 1) then
                matches[#matches + 1] = i
            end
        end

        if #matches == 0 then
            for i = 1, #clients do
                matches[#matches + 1] = i
            end
        end
    end

    local function show_current()
        local rows = {}

        for i = 1, #matches do
            local idx = matches[i]
            local c = clients[idx]
            local title = c.name or c.class or "Unknown"
            if #title > 40 then
                title = title:sub(1, 37) .. "..."
            end
            rows[#rows + 1] = {
                text = (idx == current_index and "> " or "  ") .. title,
                selected = idx == current_index,
            }
        end

        clear_notice()
        popup = chooser_popup.new {
            title = "Clients",
            screen = screen,
            rows = rows,
        }
    end

    local function step_current(direction)
        local position = 1

        for i, idx in ipairs(matches) do
            if idx == current_index then
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
        show_current()
    end

    rebuild_matches()
    show_current()

    awful.prompt.run {
        prompt = "Clients [Up/Down, Enter, Esc]: ",
        textbox = screen.mypromptbox.widget,
        changed_callback = function(input)
            query = input or ""
            rebuild_matches()

            local found = false
            for _, idx in ipairs(matches) do
                if idx == current_index then
                    found = true
                    break
                end
            end

            if not found then
                current_index = matches[1]
            end

            show_current()
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
                confirmed = true
                clear_notice()
                if original_focus and original_focus.valid then
                    client.focus = original_focus
                    original_focus:raise()
                end
                return false
            end

            return false
        end,
        exe_callback = function()
            confirmed = true
            clear_notice()
            local c = clients[current_index]
            if c and c.valid then
                client.focus = c
                c:raise()
            end
        end,
        done_callback = function()
            clear_notice()

            if not confirmed and original_focus and original_focus.valid then
                client.focus = original_focus
                original_focus:raise()
            end
        end,
    }
end

return M
