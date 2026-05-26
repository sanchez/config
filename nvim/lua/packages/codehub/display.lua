local Message = require("packages.codehub.message")

local M = {}
M.__index = M


function M.new(opts)
    local items = {}

    local picker = Snacks.picker.pick({
        title = "CodeHub",
        show_empty = true,
        auto_close = false,
        live = false,
        focus = "list",
        layout = {
            layout = {
                box = "vertical",
                backdrop = false,
                width = 64,
                position = "right",

                { win = "list", border = "rounded" },
                { win = "input", height = 1, border = "rounded" },
            },
        },
        matcher = { frecency = false, file = false },
        preview = "none",
        items = items,
        format = function(item, picker)
            local ret = {}

            -- Handle indentation
            local indent = string.rep("  ", item.level or 0)
            table.insert(ret, { indent, "SnacksPickerIndent" })

            -- Handle tree icons
            if #item.node.nodes > 0 then
                local icon = item.node.expanded and " " or " "
                local icon_hl = item.node.expanded and "SnacksPickerDirectory" or "Comment"
                table.insert(ret, { icon, icon_hl })
            else
                table.insert(ret, { "  ", "NonText" })
            end

            -- Handle the text
            table.insert(ret, { item.message, "SnacksPickerLabel" })

            return ret
        end,
        actions = {
            toggle_expand = function(picker, item)
                print(vim.inspect(item))
                item.node.expanded = not item.node.expanded
                picker:find() -- Refresh tree state
            end
        },
        win = {
            input = {
                keys = {
                    ["<CR>"]  = "toggle_expand",
                },
            },
        },
    })

    return setmetatable({
        items = items,
        messages = {},
        picker = picker,
        is_rendering = false
    }, M)
end


function M:refresh()
    self.picker.list.items = {}
    for _, x in ipairs(self.messages) do
        x:flatten(self.picker.list.items, 0)
    end
end


function M:add_message(message)
    local m = Message.new(message, function()
        self:refresh()
    end)
    table.insert(self.messages, m)

    self:refresh()

    return m
end


return M
