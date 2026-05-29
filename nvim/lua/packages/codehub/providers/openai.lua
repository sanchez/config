--- OpenAI API provider stub. Currently non-functional placeholder.
--- TODO: implement full tool-use loop similar to Anthropic provider.
local web = require("packages.codehub.providers.core")

local M = {}
M.__index = M

--- Factory: returns provider closure (currently hardcoded dummy call).
---@param hostname string API base URL (unused, hardcoded below)
---@param api_key string API key (unused)
---@param model_id string Model identifier (unused)
---@return function(session)
function M.new(hostname, api_key, model_id)
    return function(session)
        local url = hostname .. "/zen/go/v1/messages"
        local result = web.create_json_request("POST", url, {
            ["Content-Type"] = "application/json",
            ["X-Api-Key"] = api_key,
        }, {
            data = {
                model = model_id,
                system = "You are a helpful assistant",
                messages = {
                    {
                        content = "Hello World",
                        role = "user"
                    },
                },
                parallel_tool_calls = true,
                tools = {
                    {
                        type = "function",
                        ["function"] = {
                            name = "name",
                            description = "",
                            parameters = {
                                type = "object",
                                properties = {
                                    location = {
                                        type = "string",
                                        description = "The city and state",
                                    },
                                    unit = {
                                        type = "string",
                                        enum = { "celsius", "fahrenheit" },
                                    },
                                },
                                required = { "location" },
                            },
                        },
                    },
                },
                tool_choice = "auto"
            },
        })

        print(vim.inspect(result))
    end
end


return M
