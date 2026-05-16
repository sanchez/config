local M = {}
M.__index = M

local function make_api(method, url, apiKey, opts, on_result)
    url = "https://opencode.ai" .. url

    local arguments = {
        "curl", "-X", method, url,
        "-H", "Authorization: Bearer " .. apiKey,
        "-H", "X-Api-Key: " .. apiKey,
        "-H", "Content-Type: application/json",
    }

    if opts.data then
        table.insert(arguments, "-d")
        table.insert(arguments, vim.fn.json_encode(opts.data))
    end

    vim.system(arguments, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                on_result({ type = "success", data = obj.stdout })
            else
                on_result({ type = "error", data = obj.stderr })
            end
        end)
    end)
end

local function make_json_api(method, url, apiKey, opts, on_result)
    make_api(method, url, apiKey, opts, function(obj)
        if not obj.type == "success" then
            error(obj.data)
        end

        local res = vim.fn.json_decode(obj.data)
        on_result(res)
    end)
end

function M.list_models(apiKey, on_result)
    make_json_api("GET", "/zen/go/v1/models", apiKey, {}, function(result)
        local ids = {}
        for _, model in ipairs(result.data) do
            table.insert(ids, model.id)
        end

        on_result(ids)
    end)
end

function M.openai_request(apiKey, model, on_result)
    make_json_api("POST", "/zen/go/v1/chat/completions", apiKey, {
        data = {
            model = model,
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
    }, function(result)
        print(vim.inspect(result))
    end)
end

function M.anthropic_request(apiKey, model, on_result)
    make_json_api("POST", "/zen/go/v1/messages", apiKey, {
        data = {
            system = "You are a helpful assistant",
            model = model,
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
    }, function(result)
        print(vim.inspect(result))
    end)
end

-- function M.todo(apiKey)
--     local url = "https://opencode.ai"
--     local data = {
--         model = "gpt-4o",
--         messages = {
--             { role = "user", content = "Hello World" }
--         }
--     }
--
--     vim.system({
--         "curl", "-X", "POST", url,
--         "-H", "Authorization: Bearer " .. apiKey,
--         "-H", "Content-Type: application/json",
--         "-d", vim.fn.json_encode(data)
--     }, { text = true }, function(obj)
--         if obj.code == 0 then
--             print(obj.stdout)
--         else
--             print("Error: " .. obj.stderr)
--         end
--     end)
-- end

return M
