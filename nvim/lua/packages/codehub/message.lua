local M = {}
M.__index = M


function M.new(message, cb)
    return setmetatable({
        message = message,
        expanded = true,
        nodes = {},
        cb = cb,
    }, M)
end


function M:add_message(message)
    local m = M.new(message, self.cb)
    table.insert(self.nodes, m)

    self.cb()

    return m
end


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
