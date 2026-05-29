--- Agent registry. Wires up agents with providers + tools, exports shared history.
--- Uses OpenCode's Anthropic-compatible API by default (MiniMax model).
local vars = require("packages.core.vars").get_vars()
local api_key = vars["OPENCODE_API_KEY"]

local tools = require("packages.codehub.tools")
local Agent = require("packages.codehub.agents.agent")

local Providers = require("packages.codehub.providers")

local FakeAI = Providers.fake.new()
local MiniMax = Providers.anthropic.new("https://opencode.ai", api_key, "minimax-m2.7")
local DeepSeek = Providers.openai.new("https://opencode.ai", api_key, "deepseek-v4-pro")

--- Plan agent: can load skills to understand codebase and plan changes.
local planner = Agent.new("Plan", DeepSeek, {
    tools = {
        tools.load_skill,
    }
})

--- Research agent: can search + fetch web, load skills. For investigating topics.
local research = Agent.new("Research", DeepSeek, {
    tools = {
        tools.load_skill,
        tools.webfetch,
        tools.websearch,
    },
})

--- Builder agent: full file access + skills. Main agent for code changes.
local builder = Agent.new("Build", DeepSeek, {
    tools = {
        tools.load_skill,
        tools.get_time,
        tools.read_file,
        tools.write_file,
        tools.edit_file,
        tools.get_cwd,
        tools.list_files,
        tools.get_current_file,
    },
})

--- Shared history instance. Created with builder as default agent.
local history = require("packages.codehub.agents.history").new(builder.name)
return {
    history = history,
    agents = { planner, research, builder },
}
