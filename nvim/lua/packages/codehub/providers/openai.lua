--- OpenAI API provider stub. Currently non-functional placeholder.
--- TODO: implement full tool-use loop similar to Anthropic provider.
local web = require("packages.codehub.providers.core")

local M = {}
M.__index = M

-- Max attempts before giving up on API call.
local MAX_RETRIES = 3
-- Initial delay between retries (ms), multiplied by retry count.
local RETRY_DELAY_MS = 1000

--- Busy-wait for ms (blocks event loop; used between retries only).
local function delay_ms(ms)
    vim.wait(ms, function() return false end, 20, true)
end

--- Dispatches a tool call by name. Returns tool result or error block.
---@param history table History session (for error recording)
---@param tools table[] Tool registry (name-indexed)
---@param name string Tool name to invoke
---@param inputs table Tool arguments
---@return table Tool result or { type = "error", message }
local function call_tool(history, tools, name, inputs)
    for _, tool in pairs(tools) do
        if tool.name == name then
            return tool:execute(history, inputs)
        end
    end

    return { type = "error", message = "Failed to find tool" }
end


--- Returns the raw message history for the API payload.
---@param agent table Agent instance
---@param history table History session
---@return table[] Array of { role, content } messages
local function get_session_messages(agent, history)
    local messages = {}

    if agent.systemPrompt then
        table.insert(messages, {
            role = "system",
            content = agent.systemPrompt,
        })
    end

    for _, message in ipairs(history.history) do
        if message.content.role then
            table.insert(messages, message.content)
        else
            table.insert(messages, message)
        end
    end

    return messages
end


--- Converts tool specs to OpenAI-compatible schema format.
--- Each tool becomes { name, description, input_schema }.
---@param tools table[] Tool registry
---@return table[] Anthropic tool definitions
local function map_tools(tools)
    local ret = {}

    for _, tool in pairs(tools) do
        local tool_definition = {
            type = "function",
            ["function"] = {
                name = tool.name,
                description = tool.description,
            },
        }

        local properties = {}
        local required_properties = {}
        for _, property in ipairs(tool.inputs or {}) do
            properties[property.name] = {
                type = property.type,
                description = property.description,
            }
            if property.is_required then
                table.insert(required_properties, property.name)
            end
        end

        if properties then
            tool_definition.parameters = {
                type = "object",
                properties = properties,
                required = required_properties,
            }
        end

        table.insert(ret, tool_definition)
    end

    return ret
end


--- Fires HTTP POST to the completions endpoint. Returns parsed JSON or errors.
---@param hostname string API base URL
---@param api_key string API key for auth
---@param model_id string Model identifier
---@param agent table Agent with systemPrompt
---@param history table History session
---@param tools table[] Mapped tool definitions
---@return table|nil, string|nil Parsed response or nil + error message
local function make_request(hostname, api_key, model_id, agent, history, tools)
    local url = hostname .. "/zen/go/v1/chat/completions"
    local messages = get_session_messages(agent, history)
    tools = map_tools(tools)

    -- Build request body: system prompt, model, messages, tools.
    local result = web.create_json_request("POST", url, {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. api_key,
    }, {
        data = {
            model = model_id,
            messages = messages,
            parallel_tool_calls = true,
            tools = tools,
            reasoning_effort = "xhigh",
        },
    })

    if not result then
        error("Failed to get a result from the endpoint")
    end

    if result.error then
        if result.error.message then
            if result.error.message == "Internal server error" then
                return nil, "Internl server error"
            else
                error(result.error.message)
            end
        else
            error(vim.inspect(result.error))
        end
    end

    return result
end


--- Parses response content blocks. Handles thinking, text, tool_use.
--- Returns send_again=true to trigger another API call (tool result -> LLM).
---@param history table History session (writes costs, messages, status)
---@param tools table[] Tool registry
---@param response table Parsed API response
---@return boolean True if tool was called (needs another round)
local function handle_response(history, tools, response)
    -- print(vim.inspect(response))

    history:add_costs(response.cost, response.usage.prompt_tokens, response.usage.completion_tokens)

    local send_again = false

    if #response.choices < 1 then
        error("Failed to get an api response")
    end

    local choice = response.choices[1]
    if not choice.message then
        error("Failed to get message from response")
    end

    if choice.message.reasoning_content then
        history:add_debug_line("Thinking: " .. choice.message.reasoning_content)
    end

    if choice.message.role == "assistant" then
        history:add_message("assistant", choice.message)
    else
        error("Unsupported role: " .. choice.message.role)
    end

    if choice.message.content then
        history:_write_message("assistant", choice.message.content)
    end

    if choice.message.tool_calls then
        for _, block in ipairs(choice.message.tool_calls) do
            local name = block["function"].name
            local inputs = vim.fn.json_decode(block["function"].arguments)
            history:set_status("Calling Tool " .. name .. "...")
            print(vim.inspect(inputs))
            print(block["function"].arguments)

            local result = call_tool(history, tools, name, inputs)
            if type(result) == "table" then
                result = vim.fn.json_encode(result)
            end

            history:add_message("user", {
                role = "tool",
                tool_call_id = block.id,
                content = result,
            })

            send_again = true
        end
    end


    return send_again
end


--- Factory: returns provider closure (currently hardcoded dummy call).
---@param hostname string API base URL (unused, hardcoded below)
---@param api_key string API key (unused)
---@param model_id string Model identifier (unused)
---@return function(session)
function M.new(hostname, api_key, model_id)
    return function(agent, history, tools)

        local send_again = true

        while send_again do
            history:set_status("Thinking...")

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

            if not result then
                error("Unable to get a result")
            end

            send_again = handle_response(history, tools, result)
        end
    end
end


return M
