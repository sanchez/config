--- Message tree node for collapsible output. Each node can expand/collapse its children.
local M = {}
M.__index = M

--- Constructor. Creates node with optional callback (fires on tree mutation).
---@param message string Display text
---@param cb function|nil Called after adding children (re-render trigger)
---@return table New Message node
function M.new(message, cb)
    return setmetatable({
        message = message,
        expanded = true,
        nodes = {},
        cb = cb,
    }, M)
end


--- Appends a child message node. Triggers callback, returns new child.
---@param message string Child message text
---@return table New Message node
function M:add_message(message)
    local m = M.new(message, self.cb)
    table.insert(self.nodes, m)

    self.cb()

    return m
end


--- Recursively flattens tree into flat array. Used by Display to render messages.
---@param items table[] Accumulator array
---@param depth integer Current tree depth (indentation level)
---@return table[] Flat array of { message, level, node }
function M:flatten(items, depth)
    table.insert(items, {
        message = self.message,
        level = depth,
        node = self,
    })

    if self.expanded then
        for _, node in ipairs(self.nodes) do
            node:flatten(items, depth + 1)
        end
    end

    return items
end


return M
