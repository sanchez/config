--- Agent registry. Loads agent definitions from ~/.config/nvim/agents and .hub/agents.
--- Each agent specifies: name, description, provider, model, tools (allowed/denied), skills (allowed/denied).
--- Post-load: skills and tools filtered by allowed/denied; default callback assigned if missing.
--- Filter pattern: empty/nil allowed = {"*"} (allow all). "*" always matches. denied takes precedence.

local Loader = require("packages.codehub.config_loader")
local Providers = require("packages.codehub.providers")
local Skills = require("packages.codehub.skills")
local Tools = require("packages.codehub.tools")

--- Directories supported for custom agents
local agents_dirs = {
    vim.fn.stdpath("config") .. "/agents",
    vim.fn.getcwd() .. "/.hub/agents",
}

--- Matches an item against a single allow/deny term. "*" matches everything.
---@param item table Object with .name field
---@param term string Pattern to match
---@return boolean
local function if_matches(item, term)
    if term == "*" then
        return true
    end

    if item.name == term then
        return true
    end

    return false
end

--- Matches an item against any term in a list. OR semantics.
---@param item table
---@param terms string[]
---@return boolean
local function if_matches_any(item, terms)
    for _, term in pairs(terms) do
        if if_matches(item, term) then
            return true
        end
    end

    return false
end

--- Filters a name→object map by allowed/denied lists. Objects not matching allowed are dropped.
--- Objects matching denied are dropped regardless of allowed. Defaults to allow-all if allowed is empty.
---@param items table<string,table> Name-keyed object map
---@param opts table { allowed: string[], denied: string[] }
---@return table Filtered object map
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

    -- Add in the execute function if currently missing
    if agent.callback == nil then
        agent.callback = function(args)
            if not agent.provider then
                args.history:add_error_line("Agent does not have a provider set, please set one")
                return
            end

            args.history:add_message("user", args.input)

            local Session = require("packages.codehub.session")
            args.providers.invoke_provider(agent, args.history, function()
                Session.save(args.history:serialize())
                vim.notify("CodeHub has finished processing", "success")
            end)
        end
    end
end


return {
    agents = agents,
}
