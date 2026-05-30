local web = require("packages.codehub.providers.core")

local M = {}
M.__index = M


function M.list_models(api_key)
    local result = web.create_json_request("GET", "https://opencode.ai/zen/go/v1/models", {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. api_key,
    }, {})

    if not result then
        return {}
    end

    local ids = {}
    for _, model in ipairs(result.data) do
        table.insert(ids, model.id)
    end

    return ids
end


return M
