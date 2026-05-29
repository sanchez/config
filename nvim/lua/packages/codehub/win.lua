--- Simple floating window factory. Creates buffer + window options, opens on demand.
--- Used by Display and CommandWindow components.
local M = {}
M.__index = M

--- Constructor. Creates nofile buffer but does not open window yet.
---@param opts table|nil Config; border, width, height, zindex, relative, row, col
---@return table Win instance
function M.new(opts)
    opts = opts or {}

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    return setmetatable({
        win_opts = {
            border = opts.border or "single",
            width = opts.width or 40,
            height = opts.height or 10,
            zindex = opts.zindex or 1000,
            relative = opts.relative or "editor",
            row = opts.row or 0,
            col = opts.col or 0,
            style = opts.style or "minimal",
            noautocmd = opts.noautocmd or true,
        },

        buffer = buf,
    }, M)
end

--- Checks if underlying window is still valid.
---@return boolean True if window exists and is valid
function M:is_valid()
    return self.win and vim.api.nvim_win_is_valid(self.win) or false
end

--- Opens the floating window with configured options.
--- Idempotent: returns early if already open.
---@param lines string[]|nil Optional initial lines to write to buffer
function M:show(lines)
    if self:is_valid() then
        return
    end

    self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)

    vim.api.nvim_set_option_value("foldenable", false, { scope = "local", win = self.win })
    vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = self.win })
    vim.api.nvim_set_option_value("scrollbind", false, { scope = "local", win = self.win })
end

--- Closes the floating window. No-op if not open.
function M:close()
    if not self:is_valid() then
        return
    end

    vim.api.nvim_win_close(self.win, true)
end

return M
