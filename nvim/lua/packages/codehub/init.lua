local async = require("packages.core.async")

local vars = require("packages.core.vars").get_vars()
local ai = require("packages.core.opencode")
local apiKey = vars["OPENCODE_API_KEY"]

-- local PromptPopup = require("packages.core.promptpopup")



-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    async.exec(function()

        local model_ids = ai.list_models(apiKey)
        print(vim.inspect(model_ids))

    end)
    -- ai.list_models(apiKey, function(model_ids)
    --     vim.notify(vim.inspect(model_ids), "info")
    -- end)

    -- The fast request
    -- ai.openai_request(apiKey, "deepseek-v4-flash")

    -- The best quality
    -- ai.anthropic_request(apiKey, "minimax-m2.7")






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
