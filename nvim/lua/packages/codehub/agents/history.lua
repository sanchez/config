local M = {}
M.__index = M

-- TODO: I need to change this to be a nested history thing similar to the Message structure and then flatten this out instead

-- math.randomseed(os.time())
--
-- local function generate_id()
--     local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
--     local id = ""
--     for i = 1, 8 do
--         local rand = math.random(1, #chars)
--         id = id .. chars:sub(rand, rand)
--     end
--
--     return id
-- end

local Item = {}
Item.__index = Item

function Item.new(message)
    return setmetatable({
        message = message,
        expanded = true,
        children = {},
    }, Item)
end

function M.new()
    return setmetatable({
        items = {},
    }, M)
end


function M:add_user_message(message)
    local log = Item.new(message)
    table.insert(self.items, log)
    return log
end


function M:bind_display(display)
end


return M
