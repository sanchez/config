--- Popup window for single-line text input with cursor-relative positioning.
--- Used for quick command entry with Enter to submit and Esc to cancel.
local M = {}
M.__index = M

local Window = require("packages.core.window")

--- Constructor. Creates a cursor-anchored single-line input window.
---@param opts table|nil Config options
---@param opts.on_submit function Callback receiving input text on Enter
---@return table New PromptPopup instance
function M.new(opts)

    local on_submit = opts.on_submit

    local win = Window.new({
        relative = "cursor",
        col = 0,
        row = 1,
        height = 1
    })

    vim.keymap.set('i', '<Esc>', '<Cmd>close<CR>', { buffer = win.buffer, noremap = true })

    vim.keymap.set('i', '<CR>', function()
        print("Hello")
        local content = vim.api.nvim_get_current_line()
        vim.cmd('close')
        on_submit(content)
    end, { buffer = win.buffer, noremap = true })

    return setmetatable({
        win = win,
    }, M)
end

function M:show()
    self.win:show()
    self.win:focus()
    vim.cmd('startinsert')
    -- vim.api.nvim_feedkeys('i', 'n', false)
end

return M
