local Message = require("packages.codehub.message")

local M = {}
M.__index = M


function M.new(opts)
    opts = opts or {}
    local items = {}

    local self = setmetatable({
        items = items,
        messages = {},
        picker = picker,
        is_rendering = false
    }, M)

    local picker = Snacks.picker.pick({
        title = "CodeHub",
        show_empty = true,
        auto_close = false,
        live = false,
        focus = "input",
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
        filter = {
            transform = function(picker, filter)
                filter.pattern = ""
                return false -- don't force a full refresh
            end,
        },
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
            confirm = function(picker, item)
                if item == nil then
                    return
                end

                item.node.expanded = not item.node.expanded
                self:refresh()
            end,
            search_confirm = function(picker)
                local text = picker:filter().pattern

                if opts.cb then
                    opts.cb(text)
                end

                picker.input:set("")
            end,
        },
        win = {
            input = {
                keys = {
                    ["<CR>"] = { "search_confirm", mode = { "i", "n" } },
                },
            },
        },
    })

    self.picker = picker
    return self
end


function M:refresh()
    for i = #self.picker.list.items, 1, -1 do
        self.picker.list.items[i] = nil
    end

    self.picker.list.items = {}
    for _, x in ipairs(self.messages) do
        x:flatten(self.picker.list.items, 0)
    end

    self.picker.list:update({ force = true })
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
