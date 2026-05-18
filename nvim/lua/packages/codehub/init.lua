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

local session = Session.new(agent_provider)


local function format_token_number(num)
    if num > 1e9 then
        return string.format("%.2fb", num / 1e9)
    elseif num > 1e6 then
        return string.format("%.2fm", num / 1e6)
    elseif num > 1e3 then
        return string.format("%.2fk", num / 1e3)
    end
    return tostring(num)
end



-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    -- local model_ids = ai.list_models(apiKey)

    local pindow = Pindow.new("CodeHub", function(input)
        async.exec(function()
            session:add_message("user", input)
            session:execute()
        end)
    end)

    -- Handle updating the window whenever the session is updated
    session:set_listener(function()
        local lines = {}

        for _, block in ipairs(session.history) do
            local block_lines = vim.split(block.content, "\n")
            for _, line in ipairs(block_lines) do
                table.insert(lines, block.role .. ": " .. line)
            end
        end

        if session.is_thinking then
            table.insert(lines, "")
            table.insert(lines, "")
            table.insert(lines, "")
            table.insert(lines, "Thinking...")
        end

        table.insert(lines, "")
        table.insert(lines, 
            "Cost: $" .. session.total_cost ..
            ", I:" .. format_token_number(session.input_tokens) ..
            ", O:" .. format_token_number(session.output_tokens))

        pindow:render(lines)
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
