local PromptPopup = require("packages.core.promptpopup")

-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    local promptPopup = PromptPopup.new()
    promptPopup:show()
end)
