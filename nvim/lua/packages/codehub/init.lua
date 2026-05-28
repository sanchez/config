local async = require("packages.core.async")

-- local PromptPopup = require("packages.core.promptpopup")
local Pindow = require("packages.codehub.pindow")
local Display = require("packages.codehub.display")

local agents = require("packages.codehub.agents")
local agent_names = vim.tbl_map(function(x) return x.name end, agents.agents)
vim.keymap.set('n', '<leader>ca', function ()
    Snacks.picker.select(agent_names, { prompt = "Select Agent" }, function(choice)
        if not choice then return end
        agents.history.agent = choice
        agents.history:_update_footer()
    end)
end, { desc = "Pick what Agent to use" })


local function get_selected_agent()
    local name = agents.history.agent
    for _, agent in ipairs(agents.agents) do
        if agent.name == name then
            return agent
        end
    end
    return nil
end


vim.keymap.set("n", "<leader>cd", function()
    agents.history:reset()
end, { desc = "Clears the current agent session" })


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

    -- local display = Display.new({
    --     cb = function(text)
    --         agents.history:add_user_message(text)
    --     end
    -- })
    -- display:add_message("Hello World"):add_message("Nested")
    -- display:add_message("Another One")
end, { desc = "Opens CodeHub" })


-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
-- vim.keymap.set('n', '<leader>cc', function ()
--     -- local model_ids = ai.list_models(apiKey)
--
--     local pindow = Pindow.new("CodeHub", session.ns, session.buffer, function(input)
--         async.exec(function()
--             session:add_message("user", input)
--             session:execute()
--         end)
--     end)
-- end)
