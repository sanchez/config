local async = require("packages.core.async")

local vars = require("packages.core.vars").get_vars()
local apiKey = vars["OPENCODE_API_KEY"]

-- local Tool = require("packages.core.ai.tool")
-- local Session = require("packages.core.ai.session")
-- local OpenAIProvider = require("packages.core.ai.openai")
-- local AnthropicProvider = require("packages.core.ai.anthropic")

-- local PromptPopup = require("packages.core.promptpopup")
local Pindow = require("packages.codehub.pindow")
local Display = require("packages.codehub.display")

-- local agent_provider = AnthropicProvider.new("https://opencode.ai", apiKey, "minimax-m2.7")
-- local fast_provider = OpenAIProvider.new("https://opencode.ai", apiKey, "deepseek-v4-flash")

local agents = require("packages.codehub.agents")


-- local session = Session.new(agent_provider, {
--     Tool.new({
--         name = "get_time",
--         description = "Use to get the current system time",
--         inputs = {},
--         callback = function(inputs)
--             return os.date("%Y-%m-%d %H:%M:%S")
--         end
--     })
-- })

local agent_names = vim.tbl_map(function(x) return x.name end, agents.agents)


vim.keymap.set('n', '<leader>ca', function ()
    Snacks.picker.select(agent_names, { prompt = "Select Agent" }, function(choice)
        if not choice then return end

        print("Selected Agent: " .. choice)
    end)
end)


vim.keymap.set("n", "<leader>ct", function()
    local display = Display.new()
    display:add_message("Hello World"):add_message("Nested")
    display:add_message("Another One")
end)


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
