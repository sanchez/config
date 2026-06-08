--- OpenAI-compatible provider. Talks to opencode.ai proxy endpoint.
--- Supports: system messages (agent.content + skills + AGENTS.md), tool calls, reasoning_content.
--- Retry logic: 1 retry on failure/error, then throws. Handles parallel tool calls via recursion.
--- VARS["OPENCODE_API_KEY"] from .env required.
---
--- Flow: get_session_messages → map_tools → make_request_with_retry → handle_response → recurse if tool calls.

local MAX_RETRIES = 1
local RETY_DELAY_MS = 1000


-- local function delay_ms(ms, callback)
--     vim.wait(ms, function()
--         callback()
--     end, 20, true)
-- end


--- Builds messages array for API from agent config + history.
--- Order: agent.content (system), skills list (system), AGENTS.md (system), history messages.
--- Handles nested content format: some messages store {role, content} inside .content field — unwraps.
---@param agent table Agent definition (with .content, .skills)
---@param history table History instance (with .history array)
---@return table[] Messages array for API
local function get_session_messages(agent, history)
    local messages = {}

    if agent.content then
        table.insert(messages, {
            role = "system",
            content = agent.content,
        })
    end

    if agent.skills then
        local skills = "# Skills\nThe below skills are available for use with the `load_skill` tool:\n"
        for _, skill in pairs(agent.skills) do
            skills = skills .. "- **" .. skill.name .. ":** " .. skill.description .. "\n"
        end
        table.insert(messages, {
            role = "system",
            content = skills,
        })
    end

    -- AGENTS.md content injected as system message — optional per-project context for the model
    if AGENTS_PROMPT and AGENTS_PROMPT ~= "" then
        table.insert(messages, {
            role = "system",
            content = AGENTS_PROMPT,
        })
    end

    -- History messages may be nested {content = {role, content}}; unwrap to clean {role, content} for API
    for _, message in ipairs(history.history) do
        if message.content.role then
            table.insert(messages, message.content)
        else
            table.insert(messages, message)
        end
    end

    return messages
end


--- Converts tool definitions to OpenAI function-calling format.
--- Inputs starting with "_" are hidden from required list (private params passed out-of-band).
--- Tools with 0-1 properties skip parameters schema entirely.
---@param tools table<string,table> Tool name→definition map
---@return table[] OpenAI tool definitions
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
        for name, description in pairs(tool.inputs or {}) do
            local is_private = string.sub(name, 1, 1) == "_"
            if is_private then
                name = string.sub(name, 2)
            end

            properties[name] = {
                description = description,
            }

            if not is_private then
                table.insert(required_properties, name)
            end
        end

        if next(properties) ~= nil then
            tool_definition["function"].parameters = {
                type = "object",
                properties = properties,
                required = required_properties,
            }
        end

        table.insert(ret, tool_definition)
    end

    return ret
end


--- Single API request. POSTs to opencode.ai chat completions with model, messages, tools, reasoning_effort.
--- Calls back with parsed JSON response or nil on error.
---@param agent table
---@param history table
---@param callback fun(response: table|nil)
local function make_request(agent, history, callback)
    local url = "https://opencode.ai/zen/go/v1/chat/completions"
    local messages = get_session_messages(agent, history)
    local tools = map_tools(agent.tools)
    local api_key = VARS["OPENCODE_API_KEY"]

    HUB.create_json_request("POST", url, {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. api_key,
    }, {
        data = {
            model = agent.model,
            messages = messages,
            parallel_tools_calls = false,
            tools = tools,
            reasoning_effort = "xhigh",
        },
    }, callback)
end


--- Retry wrapper. Retries up to MAX_RETRIES times on nil response or error object.
--- Throws on final failure — caller (handle_response) catches and surfaces to user.
---@param agent table
---@param history table
---@param callback fun(response: table)
---@param count integer Current retry attempt (internal)
local function make_request_with_retry(agent, history, callback, count)
    count = count or 0

    local function error_or_retry(message)
        if count > MAX_RETRIES then
            error(message)
        end

        return make_request_with_retry(agent, history, callback, count + 1)
    end

    return make_request(agent, history, function(result)
        if not result then
            return error_or_retry("Failed to get a result from the endpoint")
        end

        if result.error then
            if result.error.message then
                return error_or_retry(result.error.message)
            end
            return error_or_retry(vim.inspect(result.error))
        end

        callback(result)
    end)
end


--- Processes API response. Tracks costs, handles reasoning_content (logged as debug), processes tool calls.
--- Returns send_again=true if any tool calls found — caller loops recursively until no more tool calls.
--- Tool results appended as "tool" role messages so the model can continue processing.
---@param history table
---@param response table API response
---@return boolean send_again True if tool calls require another round
local function handle_response(history, response)
    history:add_costs(response.cost, response.usage.prompt_tokens, response.usage.completion_tokens)

    local send_again = false
    history:set_status("Processing response")

    if #response.choices < 1 then
        error("Failed to get an api response")
    end

    local choice = response.choices[1]
    if not choice.message then
        error("Failed to get message from response")
    end

    history:add_message("assistant", choice.message)

    if choice.message.reasoning_content then
        history:add_debug_line("Thinking: " .. choice.message.reasoning_content)
    end

    if choice.message.role ~= "assistant" then
        error("Unsupported role: " .. choice.message.role)
    end

    if choice.message.content and choice.message.content ~= "" then
        history:_write_message("assistant", choice.message.content)
    end

    for _, block in ipairs(choice.message.tool_calls or {}) do
        local name = block["function"].name
        local inputs = vim.fn.json_decode(block["function"].arguments)
        history:set_status("Calling Tool " .. name .. "...")

        local result = HUB.call_tool(history, name, inputs)
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

    return send_again
end


--- Entry point. Recursive: sends request, processes response, loops if tool calls require more rounds.
--- Sets status "Thinking..." during API wait, clears on completion.
---@param agent table
---@param history table
---@param callback fun() Called when conversation round is complete (no more tool calls)
local function execute(agent, history, callback)
    history:set_status("Thinking...")
    return make_request_with_retry(agent, history, function(response)
        local send_again = handle_response(history, response)

        if send_again then
            return execute(agent, history, callback)
        end

        history:set_status(nil)
        callback()
    end)
end

return execute
