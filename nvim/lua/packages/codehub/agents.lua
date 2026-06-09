local Loader = require("packages.codehub.config_loader")
local Providers = require("packages.codehub.providers")
local Skills = require("packages.codehub.skills")
local Tools = require("packages.codehub.tools")

--- Directories supports for custom agents
local agents_dirs = {
    vim.fn.stdpath("config") .. "/agents",
    vim.fn.getcwd() .. "/.hub/agents",
}


local function if_matches(item, term)
    if term == "*" then
        return true
    end

    if item.name == term then
        return true
    end

    return false
end


local function if_matches_any(item, terms)
    for _, term in pairs(terms) do
        if if_matches(item, term) then
            return true
        end
    end

    return false
end


local function filter(items, opts)
    opts = opts or {}

    local allowed = opts.allowed or {}
    if #allowed == 0 then
        allowed = { "*" }
    end

    local denied = opts.denied or {}

    local result = {}
    for key, value in pairs(items) do
        if if_matches_any(value, allowed) and not if_matches_any(value, denied) then
            result[key] = value
        end
    end

    return result
end


local agents = Loader.load_objects_from_paths(agents_dirs)


-- Post process the skills and tools available to the agent based on the allowed and denied list
for _, agent in pairs(agents) do
    agent.skills = filter(Skills.skills, agent.skills)
    agent.tools = filter(Tools.tools, agent.tools)
end


return {
    agents = agents,
}
