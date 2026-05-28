local async = require("packages.core.async")
local skills = require("packages.codehub.tools.skills")

local M = {}
M.__index = M


local agentsDir = vim.fn.stdpath("config") .. "/agents"
if vim.fn.isdirectory(agentsDir) == 0 then
    vim.fn.mkdir(agentsDir, "p")
end


function M.new(name, provider, opts)
    opts = opts or {}

    local systemPrompt = ""

    -- Loads the agent system instructions from the root dir if it exists
    pcall(function()
        local agentFile = agentsDir .. "/" .. name:lower() .. ".md"
        local systemPromptLines = vim.fn.readfile(agentFile)
        systemPrompt = systemPrompt .. table.concat(systemPromptLines, "\n")
    end)

    -- Loads a top level AGENTS.md if it exists
    pcall(function()
        local agentFile = vim.fn.getcwd() .. "/AGENTS.md"
        local systemPromptLines = vim.fn.readfile(agentFile)
        systemPrompt = systemPrompt .. table.concat(systemPromptLines, "\n")
    end)

    -- Add skills into the instructions
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


-- function M:call_tool(name, inputs)
--     for _, tool in ipairs(self.tools) do
--         if tool.name == name then
--             return tool:execute(inputs)
--         end
--     end
--
--     return { type = "error", message = "Failed to find tool" }
-- end


function M:execute(history)
    history:set_status("Thinking...")
    history:add_debug_line("Starting request...")

    self.provider(self, history, self.tools)

    history:set_status(nil)
end


return M
