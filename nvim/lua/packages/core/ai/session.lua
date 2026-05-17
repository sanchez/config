local M = {}
M.__index = M


function M.new(endpoint_func)
    return setmetatable({
        history = {},
        endpoint_func = endpoint_func,
        total_cost = 0,
        input_tokens = 0,
        output_tokens = 0,
    }, M)
end


function M:add_message(role, message)
    local role_options = {
        user = true,
        assistant = true,
        system = true,
    }

    if not role_options[role] then
        error(role .. " is not in list of supported roles")
    end

    table.insert(self.history, {
        role = role,
        content = message,
    })
end

function M:add_costs(cost, input_tokens, output_tokens)
    self.total_cost = self.total_cost + cost
    self.input_tokens = self.input_tokens + input_tokens
    self.output_tokens = self.output_tokens + output_tokens
end

function M:execute()
    local result = self.endpoint_func(self)
end


return M
