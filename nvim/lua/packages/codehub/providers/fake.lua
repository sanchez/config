local web = require("packages.codehub.providers.core")


local M = {}
M.__index = M


local function call_tool(tools, name, inputs)
    for _, tool in ipairs(tools) do
        if tool.name == name then
            return tool:execute(inputs)
        end
    end

    return { type = "error", message = "Failed to find tool" }
end


function M.new()
    return function(history, tools)
        history:set_status("Thinking...")

        web.fake_request()
        history:add_message("assistant", "Hey there")

        web.fake_request()
        history:add_debug_line("Calling Tool: get_time")
        history:add_message("assistant", {
            type = "tool_call",
            tool_name = "get_time",
        })

        local result = call_tool(tools, "get_time", {})
        if type(result) == "table" then
            result = vim.fn.json_encode(result)
        end

        history:add_debug_line("Tool Result: " .. result)

        history:add_message("user", {{
            type = "tool_result",
            content = result
        }})

        web.fake_request()
        history:add_message("assistant", "Yeah look, I called the tool, it returned something, but I don't understand")
    end
end

return M
