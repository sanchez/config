--- Agent factory. Creates agent instances from name + provider + tools.
--- Loads system prompt from agents/ dir and skills/ at startup.
local async = require("packages.core.async")
local skills = require("packages.codehub.tools.skills")

local M = {}
M.__index = M

--- Directory containing agent markdown definition files.
local agentsDir = vim.fn.stdpath("config") .. "/agents"
if vim.fn.isdirectory(agentsDir) == 0 then
    vim.fn.mkdir(agentsDir, "p")
end

--- Constructor. Loads system prompt fromfile + workspace AGENTS.md + skills section.
---@param name string Agent identifier (used to find agent file: agents/{name}.md)
---@param provider function Provider closure returned by Providers.*.new()
---@param opts table|nil Options dict; .tools overrides default tool list
---@return table Agent instance
function M.new(name, provider, opts)
    opts = opts or {}

    local systemPrompt = ""

    -- Load agent-specific instructions from agents/{name}.md in nvim config dir.
    pcall(function()
        local agentFile = agentsDir .. "/" .. name:lower() .. ".md"
        local systemPromptLines = vim.fn.readfile(agentFile)
        systemPrompt = systemPrompt .. table.concat(systemPromptLines, "\n")
    end)

    -- Load workspace-level agent instructions from ./AGENTS.md in cwd.
    pcall(function()
        local agentFile = vim.fn.getcwd() .. "/AGENTS.md"
        local systemPromptLines = vim.fn.readfile(agentFile)
        systemPrompt = systemPrompt .. table.concat(systemPromptLines, "\n")
    end)

    -- Append auto-generated skills section listing available load_skill targets.
    if skills.skills then
        systemPrompt = systemPrompt .. "\n\n# Skills\nThe below skills are available for use with the `load_skill` tool:\n"
        for skill_name, skill in pairs(skills.skills) do
            systemPrompt = systemPrompt .. "- **" .. skill_name .. ":** " .. skill.description .. "\n"
        end
    end

    return setmetatable({
        name = name,
        systemPrompt = systemPrompt,
        provider = provider,
        tools = opts.tools or {}
    }, M)
end

--- Executes the agent: calls provider closure with agent, history, tools.
--- Updates status throughout, sets to nil on completion.
---@param history table History session for this agent
function M:execute(history)
    history:set_status("Thinking...")
    history:add_debug_line("Starting request...")

    self.provider(self, history, self.tools)

    history:set_status(nil)
end


return M
