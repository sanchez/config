local M = {}
M.__index = M

-- TODO: I need to change this to be a nested history thing similar to the Message structure and then flatten this out instead

function M.new()
    return setmetatable({
        items = {},
    }, M)
end


function M:add_message(role, message)
    local role_options = {
        user = true,
        assistant = true,
    }

    if not role_options[role] then
        error(role .. " is not in list of supported roles")
    end

    table.insert(self.items, {
        role = role,
        content = message,
    })
end


return M
