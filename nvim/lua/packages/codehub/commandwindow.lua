local M = {}
M.__index = M

local Win = require("win")

function M.new(opts)
    local win = Win.new({
        relative = "cursor",
        col = 0,
        row = 1,
    })

    return setmetatable({
        win = win
    })
end

function M:show(lines)
    self.win:show(lines)
end
