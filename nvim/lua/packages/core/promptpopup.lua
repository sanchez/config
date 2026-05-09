local M = {}
M.__index = M

local Window = require("packages.core.window")

function M.new()
    local win = Window.new({
        relative = "cursor",
        col = 0,
        row = 1,
    })

    return setmetatable({
        win = win,
    }, M)
end

function M:show()
    self.win:show()
end

return M
