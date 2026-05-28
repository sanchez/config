local web = require("packages.codehub.providers.core")


local M = {}
M.__index = M

local MAX_RETRIES = 3
local RETRY_DELAY_MS = 1000

local function delay_ms(ms)
    vim.wait(ms, function() return false end, 20, true)
end

local function call_tool(history, tools, name, inputs)
    for _, tool in pairs(tools) do
        if tool.name == name then
            return tool:execute(history, inputs)
        end
    end

    return { type = "error", message = "Failed to find tool" }
end


local function get_session_messages(agent, history)
    -- local messages = {}
    --
    -- if agent.systemPrompt then
    --     table.insert(messages, {
    --         role = "system",
    --         content = agent.systemPrompt
    --     })
    -- end
    --
    -- for _, message in ipairs(history.history) do
    --     table.insert(messages, message)
    -- end
    --
    -- print(vim.inspect(messages))
    --
    -- return messages
    return history.history
end


local function map_tools(tools)
    local ret = {}
    for _, tool in pairs(tools) do
        local tool_definition = {
            name = tool.name,
            description = tool.description,
        }

        local properties = {}
        local required_properties = {}
        for _, property in ipairs(tool.inputs or {}) do
            properties[property.name] = {
                type = property.type,
                description = property.description
            }
            if property.is_required then
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

        table.insert(ret, tool_definition)
    end

    return ret
end


local function make_request(hostname, api_key, model_id, agent, history, tools)
    local url = hostname .. "/zen/go/v1/messages"
    local messages = get_session_messages(agent, history)
    tools = map_tools(tools)

    local result = web.create_json_request("POST", url, {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = api_key,
    }, {
        data = {
            system = agent.systemPrompt,
            model = model_id,
            messages = messages,
            temperature = 1,
            thinking = {
                type = "adaptive",
            },
            tools = tools,
            output_config = {
                effort = "max",
            },
        },
    })

    if not result then
        error("Failed to get a result from the endpoint")
    end

    if result.error then
        if result.error.message then
            if result.error.message == "Internal server error" then
                return nil, "Internal server error"
            else
                error(result.error.message)
            end
        else
            error(vim.inspect(result.error))
        end
    end

    return result
end


local function handle_response(history, tools, response)
    history:add_costs(response.cost, response.usage.input_tokens, response.usage.output_tokens)

    local send_again = false

    for i, block in ipairs(response.content) do
        if block.type == "thinking" then
            history:add_debug_line("Thinking: " .. block.thinking)
            history:add_message("assistant", {{
                type = "thinking",
                signature = block.signature,
                thinking = block.thinking,
            }})
        elseif block.type == "text" then
            history:add_message("assistant", block.text)
        elseif block.type == "tool_use" then
            history:set_status("Calling Tool " .. block.name .. "...")
            history:add_message("assistant", { block }, false)

            local result = call_tool(history, tools, block.name, block.input)
            if type(result) == "table" then
                result = vim.fn.json_encode(result)
            end

            history:add_message("user", {{
                type = "tool_result",
                tool_use_id = block.id,
                content = result
            }}, false)

            send_again = true

        else
            history:add_error_line("Unknown role: " .. block.type)
            history:add_debug_line(vim.inspect(block))
        end
    end

    return send_again
end


function M.new(hostname, api_key, model_id)
    return function(agent, history, tools)

        local send_again = true

        while send_again do
            history:set_status("Thinking")

            local retries = 0
            local result, err = make_request(hostname, api_key, model_id, agent, history, tools)

            while err and retries < MAX_RETRIES do
                retries = retries + 1
                history:set_status("Retrying request (" .. retries .. "/" .. MAX_RETRIES .. ")...")
                delay_ms(RETRY_DELAY_MS * retries)
                result, err = make_request(hostname, api_key, model_id, agent, history, tools)
            end

            if err then
                error(err)
            end

            send_again = handle_response(history, tools, result)
        end

    end
end


return M
