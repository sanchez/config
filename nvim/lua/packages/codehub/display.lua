--- Snacks-based display with collapsible message tree.
--- Layout: right-pinned vertical with display window + single-line input below.
--- Note: unused in current CodeHub flow (replaced by Pindow + history buffer).
local Message = require("packages.codehub.message")

local M = {}
M.__index = M

--- Constructor. Creates display + input windows via Snacks, arranges via layout.
---@param opts table|nil Config options (currently unused)
---@return table Display instance
function M.new(opts)
    opts = opts or {}

    local self = setmetatable({
        messages = {}
    }, M)

    -- Display window (read-only, shows messages)
    self.display_win = Snacks.win({
        show = false,
        enter = false,
        bo = { modifiable = false, buftype = "nofile" },
        wo = { wrap = true },
    })

    -- Input window (prompt buffer, anchored below display)
    self.input_win = Snacks.win({
        show = false,
        enter = true,
        height = 1,
        bo = { buftype = "nofile" },
        on_win = function(win)
            vim.keymap.set({ "i", "n" }, "<CR>", function()
                local lines = vim.api.nvim_buf_get_lines(win.buf, 0, -1, false)
                local text = table.concat(lines, "\n")
                if text == "" then return end

                vim.notify(text, "info")

                vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, { "" })
            end, { buffer = win.buf })
        end,
    })

    -- Right-pinned vertical layout with messages pane + single-line input at bottom
    self.layout = Snacks.layout.new({
        wins = {
            display = self.display_win,
            input = self.input_win,
        },
        layout = {
            box = "vertical",
            position = "right",
            width = 64,
            backdrop = false,

            { win = "display", border = "rounded", title = "CodeHub" },
            { win = "input", height = 1, border = "rounded" },
        },
        on_update = function()
            if self.input_win:valid() and not self._focused then
                self._focused = true
                self.input_win:focus()
                vim.api.nvim_win_call(self.input_win.win, function()
                    vim.cmd("startinsert!")
                end)
            end
        end,
    })

    return self
end

--- Re-renders all messages to display buffer as indented lines.
--- Flattens tree structure into flat text with depth-based indentation.
function M:render()
    local lines = {}
    for _, msg in ipairs(self.messages) do
        msg:flatten(lines, 0)
    end

    local text = vim.tbl_map(function(item)
        return string.rep("  ", item.level or 0) .. (item.message or "")
    end, lines)

    vim.bo[self.display_win.buf].modifiable = true
    vim.api.nvim_buf_set_lines(self.display_win.buf, 0, -1, false, text)
    vim.bo[self.display_win.buf].modifiable = false
end

--- Appends a message node to the tree, triggers re-render.
--- Typo "add_messsage" preserved — search for callers before renaming.
---@param message string Display text
---@return Message New Message node
function M:add_messsage(message)
    local m = Message.new(message, function()
        self:render()
    end)

    table.insert(self.messages, m)
    self:render()
    return m
end


return M
