local async = require("packages.core.async")

local vars = require("packages.core.vars").get_vars()
local apiKey = vars["OPENCODE_API_KEY"]

local Session = require("packages.core.ai.session")
local OpenAIProvider = require("packages.core.ai.openai")
local AnthropicProvider = require("packages.core.ai.anthropic")

-- local PromptPopup = require("packages.core.promptpopup")
local Pindow = require("packages.codehub.pindow")

local agent_provider = AnthropicProvider.new("https://opencode.ai", apiKey, "minimax-m2.7")
local fast_provider = OpenAIProvider.new("https://opencode.ai", apiKey, "deepseek-v4-flash")



-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    async.exec(function()
        -- local model_ids = ai.list_models(apiKey)

        -- local session = Session.new(agent_provider)
        -- session:add_message("user", "Hello, tell me about yourself")
        -- session:execute()
        --
        -- session:debug()

        local pindow = Pindow.new()

    end)





    -- vim.ui.input({ prompt = "Prompt: "}, function(input)
    --     vim.notify(input, "info")
    -- end)

    -- vim.ui.select({ "tabs", "spaces" }, {
    --     prompt = "Select tabs or spaces:",
    --     format_item = function(item)
    --         return ('I choose %s!'):format(item)
    --     end,
    --     preview_item = function(item)
    --         local lines = { "This is " .. vim.inspect(item) }
    --         local buf = vim.api.nvim_create_buf(false, true)
    --     end
    -- )

    -- local promptPopup = PromptPopup.new({
    --     on_submit = function(content)
    --         print(content)
    --     end
    -- })

    -- promptPopup:show()
end)
