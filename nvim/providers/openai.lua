local MAX_RETRIES = 1
local RETY_DELAY_MS = 1000


-- local function delay_ms(ms, callback)
--     vim.wait(ms, function()
--         callback()
--     end, 20, true)
-- end


local function get_session_messages(agent, history)
    local messages = {}

    -- if agent.content then
    --     table.insert(messages, {
    --         role = "system",
    --         content = agent.content,
    --     })
    -- end

    -- if agent.skills then
    --     local skills = "# Skills\nThe below skills are available for use with the `load_skill` tool:\n"
    --     for _, skill in pairs(agent.skills) do
    --         skills = skills .. "- **" .. skill.name .. ":** " .. skill.description .. "\n"
    --     end
    --     table.insert(messages, {
    --         role = "system",
    --         content = skills,
    --     })
    -- end

    if AGENTS_PROMPT and AGENTS_PROMPT ~= "" then
        table.insert(messages, {
            role = "system",
            content = AGENTS_PROMPT,
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

        if #properties > 1 then
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
            parallel_tools_calls = true,
            tools = tools,
            reasoning_effort = "xhigh",
        },
    }, callback)
end


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
