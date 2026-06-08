--- CodeHub entry point. Wires keymaps, agent selection, and Pindow popup.
--- Keymaps:
---   <leader>cc - Open CodeHub prompt
---   <leader>ca - Pick agent
---   <leader>cd - Reset session

local Pindow = require("packages.codehub.pindow")

-- local tools = require("packages.codehub.tools")
-- local skills = require("packages.codehub.skills")

local agents = require("packages.codehub.agents")
-- Select first agent as default. selected_agent is a string (agent name), not the agent object.
local selected_agent, _ = next(agents.agents, nil)
-- agent_list is used by the picker (Snacks.picker.select).
local agent_list = {}
for _, agent in pairs(agents.agents) do
    local name = agent.name
    -- if agent.description then
    --     name = name .. " - " .. agent.description
    -- end

    table.insert(agent_list, name)
end

local providers = require("packages.codehub.providers")
local skills = require("packages.codehub.skills")
local tools = require("packages.codehub.tools")


local History = require("packages.codehub.history")
local history = History.new(selected_agent)


--- Keymap: pick agent from list. Updates shared history's default agent.
vim.keymap.set('n', '<leader>ca', function ()
    Snacks.picker.select(agent_list, { prompt = "Select Agent" }, function(choice)
        if not choice then return end

        selected_agent = choice
        history.agent = choice
        history:_update_footer()
    end)
end, { desc = "Pick what Agent to use" })

--- Looks up agent by name in registry.
---@return table|nil Agent instance
local function get_selected_agent()
    local name = history.agent
    for _, agent in pairs(agents.agents) do
        if agent.name == name then
            return agent
        end
    end
    return nil
end

--- Keymap: clear session. Resets history (messages, costs, status).
vim.keymap.set("n", "<leader>cd", function()
    history:reset()
end, { desc = "Clears the current agent session" })

local function handle_execute(input)
    local agent = get_selected_agent()
    if agent == nil then
        history:add_error_line("Unable to find agent: " .. history.agent)
        return
    end

    if agent.callback then
        agent.callback({
            input = input,
            history = history,
            agents = agents,
            providers = providers,
            skills = skills,
            tools = tools,
        })
        return
    end

    if not agent.provider then
        history:add_error_line("Agent does not have a provider set, please set one")
        return
    end

    history:add_message("user", input)

    providers.invoke_provider(agent, history, function()
        vim.notify("CodeHub has finished processing", "success")
    end)
end

--- Keymap: open CodeHub. Creates Pindow, registers Enter handler.
--- Adds user message to history, then runs agent:execute() async.
vim.keymap.set("n", "<leader>cc", function()
    Pindow.new("CodeHub", history.ns, history.buffer, function(input)
        handle_execute(input)
    end)
end, { desc = "Opens CodeHub" })
