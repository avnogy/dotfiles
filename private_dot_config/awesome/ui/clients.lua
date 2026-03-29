local awful = require("awful")
local popup_menu = require("ui.popup_menu")

local M = {}

function M.choose()
    local screen = awful.screen.focused()
    if #client.get() == 0 then
        return
    end

    popup_menu.run {
        title = "Clients",
        screen = screen,
        promptbox = screen.mypromptbox.widget,
        entries = (function()
            local entries = {}

            for _, c in ipairs(client.get()) do
                if c.valid then
                    entries[#entries + 1] = c
                end
            end

            return entries
        end)(),
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
        recalculate = function(ctx)
            local lowered = ctx.query:lower()
            local matches = {}

            for _, c in ipairs(ctx.entries) do
                local client_title = (c.name or ""):lower()
                local class = (c.class or ""):lower()
                if lowered == ""
                    or client_title == lowered
                    or client_title:find("^" .. lowered, 1)
                    or client_title:find(lowered, 1, true)
                    or class == lowered
                    or class:find("^" .. lowered, 1)
                    or class:find(lowered, 1, true) then
                    matches[#matches + 1] = c
                end
            end

            if #matches == 0 then
                return ctx.entries
            end

            return matches
        end,
        render = function(c)
            -- Render the label shown in the chooser, including the first tag when available.
            local item_title = c.name or c.class or "Unknown"

            if #item_title > 40 then
                item_title = item_title:sub(1, 37) .. "..."
            end

            if c.first_tag and c.first_tag.name ~= "" then
                item_title = string.format("%s [%s]", item_title, c.first_tag.name)
            end

            return {
                text = item_title,
            }
        end,
        commit = function(c)
            -- Jumping to a client delegates screen/tag selection to Awesome itself.
            if c and c.valid then
                c:jump_to(false)
            end
        end,
    }
end

return M
