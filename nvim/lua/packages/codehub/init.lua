local PromptPopup = require("packages.core.promptpopup")

-- TODO: I want to change this to be based on visual mode, if the user has lines selected then open the prompt window to provide a prompt
vim.keymap.set('n', '<leader>c', function ()
    print("CodeHub!")
    local promptPopup = PromptPopup.new({
        on_submit = function(content)
            print(content)
        end
    })

    promptPopup:show()
end)
