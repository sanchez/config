--- Anthropic API provider. Executes agent loop with retry logic + tool handling.
--- Uses OpenCode's /zen/go/v1/messages endpoint (Anthropic-compatible).
local web = require("packages.codehub.providers.core")


local M = {}
M.__index = M

--- Max attempts before giving up on API call.
local MAX_RETRIES = 3
--- Initial delay between retries (ms), multiplied by retry count.
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
--- Note: system prompt sent separately in request body.
---@param agent table Agent instance (system prompt accessed elsewhere)
---@param history table History session
---@return table[] Array of { role, content } messages
local function get_session_messages(agent, history)
    -- local messages = {}
    --
    -- if agent.systemPrompt then
    --     table.insert(messages, {
    --         role = "system",
    --         content = agent.systemPrompt,
    --     })
    -- end
    --
    -- for _, message in ipairs(history.history) do
    --     table.insert(messages, message)
    -- end
    --
    -- return messages

    return history.history
end

--- Converts tool specs to Anthropic-compatible schema format.
--- Each tool becomes { name, description, input_schema }.
---@param tools table[] Tool registry
---@return table[] Anthropic tool definitions
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

--- Fires HTTP POST to the messages endpoint. Returns parsed JSON or errors.
---@param hostname string API base URL
---@param api_key string API key for auth
---@param model_id string Model identifier
---@param agent table Agent with systemPrompt
---@param history table History session
---@param tools table[] Mapped tool definitions
---@return table|nil, string|nil Parsed response or nil + error message
local function make_request(hostname, api_key, model_id, agent, history, tools)
    local url = hostname .. "/zen/go/v1/messages"
    local messages = get_session_messages(agent, history)
    tools = map_tools(tools)

    -- Build request body: system prompt, model, messages, tools.
    -- Enables extended thinking (adaptive) and max effort output.
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


--- Parses response content blocks. Handles thinking, text, tool_use.
--- For tool_use: executes tool, appends result as user message.
--- Returns send_again=true to trigger another API call (tool result -> LLM).
---@param history table History session (writes costs, messages, status)
---@param tools table[] Tool registry
---@param response table Parsed API response with .content and .usage
---@return boolean True if tool was called (needs another round)
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


--- Factory: returns provider closure that runs the agent loop.
--- Loops make_request -> handle_response until no tool calls remain.
--- Retries transient failures up to MAX_RETRIES with backoff.
---@param hostname string API base URL
---@param api_key string API key
---@param model_id string Model identifier
---@return function(agent, history, tools)
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

            if not result then
                error("Unable to get a result")
            end

            send_again = handle_response(history, tools, result)
        end

    end
end


return M
