local Loader = require("packages.codehub.config_loader")
local Skills = require("packages.codehub.skills")
local Tools = require("packages.codehub.tools")
local Net = require("packages.codehub.net")
VARS = require("packages.core.vars").get_vars()


--- Directories supported for providers
local providers_dirs = {
    vim.fn.stdpath("config") .. "/providers",
    vim.fn.getcwd() .. "/.hub/providers",
}


HUB = {}
HUB.call_tool = Tools.call_tool
HUB.create_request = Net.create_request
HUB.create_json_request = Net.create_json_request

AGENTS_PROMPT = ""
pcall(function()
    local agentFile = vim.fn.getcwd() .. "/AGENTS.md"
    local systemPromptLines = vim.fn.readfile(agentFile)
    AGENTS_PROMPT = table.concat(systemPromptLines, "\n")
end)


local providers = Loader.load_objects_from_paths(providers_dirs)


local function get_provider(name)
    for _, provider in pairs(providers) do
        if provider.name == name then
            return provider
        end
    end

    error("Failed to find provider: " .. name)
end


local function invoke_provider(agent, history, callback)
    local provider = get_provider(agent.provider)
    return provider.callback(agent, history, callback)
end

return {
    providers = providers,
    invoke_provider = invoke_provider,
}
