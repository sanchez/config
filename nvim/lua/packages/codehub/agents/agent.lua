local async = require("packages.core.async")

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

    return { type = "error", message = "Failed to find tool" }
end


function M:execute(history)
    history:set_status("Thinking...")
    history:add_debug_line("Starting request...")

    self.provider(history, self.tools)

    history:set_status(nil)
end


return M
