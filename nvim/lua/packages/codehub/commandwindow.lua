--- Simple command window wrapped around Win. Cursor-anchored overlay.
local M = {}
M.__index = M

local Win = require("packages.codehub.win")

--- Constructor.
---@param opts table Window options passed to Win
---@return table CommandWindow instance
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

--- Shows the window with provided lines.
---@param lines string[] Lines to display in the window
function M:show(lines)
    self.win:show(lines)
end

return M
