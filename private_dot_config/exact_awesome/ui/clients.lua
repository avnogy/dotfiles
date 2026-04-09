local awful = require("awful")
local popup_menu = require("ui.popup_menu")

local M = {}

local function get_process_name(c)
    if not c.pid then
        return nil
    end

	local proc_comm = io.open(string.format("/proc/%d/comm", c.pid), "r")
    if not proc_comm then
        return nil
    end

    local process_name = proc_comm:read("*l")
    proc_comm:close()

    return process_name ~= "" and process_name or nil
end

function M.choose()
    local screen = awful.screen.focused()
    local entries = {}

    for _, c in ipairs(client.get()) do
        if c.valid then
            local process_name = get_process_name(c)
            local item_title = c.name or c.class or "Unknown"
            if #item_title > 40 then
                item_title = item_title:sub(1, 37) .. "..."
            end

            if process_name then
                item_title = string.format("%s: %s", process_name, item_title)
            end

            if c.first_tag and c.first_tag.name ~= "" then
                item_title = string.format("%s [%s]", item_title, c.first_tag.name)
            end

            entries[#entries + 1] = {
                client = c,
                title = item_title,
                match_text = ((process_name or "") .. "\n" .. (c.name or "") .. "\n" .. (c.class or "")):lower(),
            }
        end
    end

    if #entries == 0 then
        return
    end

    popup_menu.run {
        title = "Clients",
        screen = screen,
        promptbox = screen.mypromptbox.widget,
        advance_keys = {
            { modifiers = { "Mod4" }, key = "Tab" },
        },
        entries = entries,
        text = function(entry)
            return entry.title
        end,
        snapshot = function()
            -- Client chooser only needs to restore focus when cancelled.
            return client.focus
        end,
        rollback = function(saved_focus)
            if saved_focus and saved_focus.valid then
                client.focus = saved_focus
                saved_focus:raise()
            end
        end,
        commit = function(entry)
            -- Jumping to a client delegates screen/tag selection to Awesome itself.
            if entry.client and entry.client.valid then
                entry.client:jump_to(false)
            end
        end,
    }
end

return M
