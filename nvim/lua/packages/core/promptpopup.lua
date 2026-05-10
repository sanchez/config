local M = {}
M.__index = M

local Window = require("packages.core.window")

function M.new(opts)
    opts = opts or {}

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
