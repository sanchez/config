local M = {}
M.__index = M


function M.new(name, provider, opts)
    opts = opts or {}

    return setmetatable({
        name = name,
        provider = provider,
        tools = opts.tools or {}
    }, M)
end


function M:call_tool(name, inputs)
    for _, tool in ipairs(self.tools) do
        if tool.name == name then
            return tool:execute(inputs)
        end
    end
end


function M:execute(history)
end


return M
