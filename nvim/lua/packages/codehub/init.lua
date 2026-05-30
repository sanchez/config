--- CodeHub entry point. Wires keymaps, agent selection, and Pindow popup.
--- Keymaps:
---   <leader>cc - Open CodeHub prompt
---   <leader>ca - Pick agent
---   <leader>cd - Reset session
local async = require("packages.core.async")

local Pindow = require("packages.codehub.pindow")
local agents = require("packages.codehub.agents")
local agent_names = vim.tbl_map(function(x) return x.name end, agents.agents)

--- Keymap: pick agent from list. Updates shared history's default agent.
vim.keymap.set('n', '<leader>ca', function ()
    Snacks.picker.select(agent_names, { prompt = "Select Agent" }, function(choice)
        if not choice then return end
        agents.history.agent = choice
        agents.history:_update_footer()
    end)
end, { desc = "Pick what Agent to use" })

--- Looks up agent by name in registry.
---@return table|nil Agent instance
local function get_selected_agent()
    local name = agents.history.agent
    for _, agent in ipairs(agents.agents) do
        if agent.name == name then
            return agent
        end
    end
    return nil
end

--- Keymap: clear session. Resets history (messages, costs, status).
vim.keymap.set("n", "<leader>cd", function()
    agents.history:reset()
end, { desc = "Clears the current agent session" })

--- Keymap: open CodeHub. Creates Pindow, registers Enter handler.
--- Adds user message to history, then runs agent:execute() async.
vim.keymap.set("n", "<leader>cc", function()
    local pindow = Pindow.new("CodeHub", agents.history.ns, agents.history.buffer, function(input)
        local agent = get_selected_agent()
        if agent == nil then
            agents.history:add_error_line("Unable to find agent: " .. agents.history.agent)
            return
        end

        agents.history:add_message("user", input)
        async.exec(function()
            agent:execute(agents.history)
            vim.notify("CodeHub has finished processing", "success")
        end)
    end)
end, { desc = "Opens CodeHub" })
