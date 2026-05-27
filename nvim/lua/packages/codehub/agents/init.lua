local vars = require("packages.core.vars").get_vars()
local api_key = vars["OPENCODE_API_KEY"]

local tools = require("packages.codehub.tools")
local Agent = require("packages.codehub.agents.agent")

local Providers = require("packages.codehub.providers")
local MiniMax = Providers.anthropic.new("https://opencode.ai", api_key, "minimax-m2.7")
-- local DeepSeek = Providers.openai.new("https://opencode.ai", api_key, "deepseek-v4-flash")


local planner = Agent.new("Plan", MiniMax, {})
local research = Agent.new("Research", MiniMax, {})

local builder = Agent.new("Build", MiniMax, {
    tools = { tools.get_time },
})


local history = require("packages.codehub.agents.history").new(builder.name)
return {
    history = history,
    agents = { planner, research, builder },
}
