local web = require("packages.core.ai.core")


local M = {}
M.__index = M


local function get_session_messages(session)
    local messages = {}
    for _, message in ipairs(session.history) do
        table.insert(messages, {
            role = message.role,
            content = message.content,
        })
    end

    return messages
end


local function get_session_tools(session)
    local tools = {}
    for _, tool in ipairs(session.tools) do
        local tool_definition = {
            name = tool.name,
            description = tool.description,
        }

        local properties = {}
        local required_properties = {}
        for _, property in ipairs(tool.inputs) do
            properties[property.name] = {
                type = property.name,
                description = property.description
            }
            if property.is_reuqired then
                table.insert(required_properties, property.name)
            end
        end

        if properties then
            tool_definition.input_schema = {
                type = "object",
                properties = properties,
                required = required_properties,
            }
        end

        table.insert(tools, tool_definition)
    end

    return tools
end


local function make_request(hostname, api_key, model_id, session)
    local url = hostname .. "/zen/go/v1/messages"
    local messages = get_session_messages(session)
    local tools = get_session_tools(session)

    local result = web.create_json_request("POST", url, {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = api_key,
    }, {
        data = {
            system = "You are a helpful assistant",
            model = model_id,
            messages = messages,
            temperature = 1,
            thinking = {
                type = "adaptive",
            },
            tools = tools,
        },
    })

    if not result then
        error("Failed to get a result from the endpoint")
    end

    if result.error then
        -- There was an error in the endpoint, need to throw it so it doesn't go silently
        if result.error.message then
            error(result.error.message)
        else
            error(vim.inspect(result.error))
        end
    end

    return result
end


local function handle_response(session, response)
    session:add_costs(response.cost, response.usage.input_tokens, response.usage.output_tokens)

    for i, block in ipairs(response.content) do
        if block.type == "thinking" then
            -- We currently skip thinking blocks
            -- TODO: Add support for thinking blocks
        elseif block.type == "text" then
            session:add_message("assistant", block.text)
        else
            print("Found unsupported role: " .. block.type)
        end
    end
end


function M.new(hostname, api_key, model_id)
    return function(session)

        local result = make_request(hostname, api_key, model_id, session)
        handle_response(session, result)

        -- print(vim.inspect(result))

    end
end


return M
