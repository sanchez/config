local web = require("packages.core.ai.core")

local M = {}
M.__index = M

function M.new(hostname, api_key, model_id)
    return function(session)

        local url = hostname .. "/zen/go/v1/messages"
        local result = web.create_json_request("POST", url, {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = api_key,
        }, {
            data = {
                system = "You are a helpful assistant",
                model = model_id,
                messages = {
                    {
                        content = "Hello World",
                        role = "user"
                    },
                },
                temperature = 1,
                thinking = {
                    type = "adaptive",
                },
                tools = {
                    {
                        name = "name",
                        input_schema = {
                            type = "object",
                            properties = {
                                location = "bar",
                                unit = "bar",
                            },
                            required = {
                                "location"
                            },
                        },
                    },
                },
            },
        })

        print(vim.inspect(result))

    end
end

return M
