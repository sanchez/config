local vars = require("packages.core.vars").get_vars()

-- local PromptPopup = require("packages.core.promptpopup")



-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    vim.notify("CodeHub!", "info")

    vim.notify(vim.inspect(vars), "info")

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
