local async = require("packages.core.async")

local M = {}
M.__index = M


local agentsDir = vim.fn.stdpath("config") .. "/agents"
if vim.fn.isdirectory(agentsDir) == 0 then
    vim.fn.mkdir(agentsDir, "p")
end


function M.new(name, provider, opts)
    opts = opts or {}

    local agentFile = agentsDir .. "/" .. name:lower() .. ".md"
    local systemPrompt = nil
    pcall(function()
        local systemPromptLines = vim.fn.readfile(agentFile)
        systemPrompt = table.concat(systemPromptLines, "\n")
    end)

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
