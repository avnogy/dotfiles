local awful = require("awful")
local popup_menu = require("ui.popup_menu")

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

function M.choose()
    local screen = awful.screen.focused()
    local tag = screen.selected_tag
    if not tag then
        return
    end

    popup_menu.run {
        title = "Layout",
        screen = screen,
        promptbox = screen.mypromptbox.widget,
        entries = (function()
            local entries = {}

            for _, layout in ipairs(M.available) do
                entries[#entries + 1] = {
                    layout = layout,
                    name = awful.layout.getname(layout),
                }
            end

            return entries
        end)(),
        current_index = (function()
            local current_layout = awful.layout.get(tag.screen)

            for index, layout in ipairs(M.available) do
                if layout == current_layout then
                    return index
                end
            end

            return 1
        end)(),
        snapshot = function()
            -- Layout preview mutates tag layout and can move clients, so capture enough to undo it.
            local tx = {
                original_layout = awful.layout.get(tag.screen),
                original_focus = client.focus,
                original_clients = {},
            }

            for _, c in ipairs(tag:clients()) do
                -- Layout preview can move windows around, so keep enough state to undo it on cancel.
                tx.original_clients[c] = {
                    floating = c.floating,
                    maximized = c.maximized,
                    maximized_horizontal = c.maximized_horizontal,
                    maximized_vertical = c.maximized_vertical,
                    fullscreen = c.fullscreen,
                    geometry = c:geometry(),
                }
            end

            return tx
        end,
        rollback = function(tx)
            -- Cancel restores both the original layout and the client state it affected.
            awful.layout.set(tx.original_layout, tag)

            for c, state in pairs(tx.original_clients) do
                if c.valid then
                    -- Restore flags first so geometry writes are not ignored by fullscreen/maximized states.
                    c.floating = state.floating
                    c.maximized = state.maximized
                    c.maximized_horizontal = state.maximized_horizontal
                    c.maximized_vertical = state.maximized_vertical
                    c.fullscreen = state.fullscreen

                    if not state.maximized and not state.maximized_horizontal
                        and not state.maximized_vertical and not state.fullscreen then
                        c:geometry(state.geometry)
                    end
                end
            end

            if tx.original_focus and tx.original_focus.valid then
                client.focus = tx.original_focus
                tx.original_focus:raise()
            end
        end,
        recalculate = function(ctx)
            local lowered = ctx.query:lower()
            local matches = {}

            for _, entry in ipairs(ctx.entries) do
                local name = entry.name:lower()
                if lowered == ""
                    or name == lowered
                    or name:find("^" .. lowered, 1)
                    or name:find(lowered, 1, true) then
                    matches[#matches + 1] = entry
                end
            end

            if #matches == 0 then
                return ctx.entries
            end

            return matches
        end,
        render = function(entry)
            return {
                text = entry.name,
            }
        end,
        preview = function(entry, tx)
            -- Preview is live: selecting an entry applies the layout immediately.
            awful.layout.set(entry.layout, tag)

            if tx.original_focus and tx.original_focus.valid then
                client.focus = tx.original_focus
                tx.original_focus:raise()
            end
        end,
        commit = function(_, tx)
            -- Commit keeps the selected layout; only focus needs to be restored.
            if tx.original_focus and tx.original_focus.valid then
                client.focus = tx.original_focus
                tx.original_focus:raise()
            end
        end,
    }
end

return M
