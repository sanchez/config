--- Floating window factory (core variant). Creates buffer + window, shows on demand, auto-closes on WinClosed.
--- Differs from packages.codehub.win: uses "testing" style default, fires stopinsert on close via autocmd.
--- Used by PromptPopup.
local M = {}
M.__index = M

--- Destructor: force-deletes the backing buffer to prevent leaks. Called by __gc or manual cleanup.
local function destructor(obj)
    vim.api.nvim_buf_delete(obj.buffer, { force = true })
end
M.__destructor = destructor

--- Constructor. Creates nofile buffer, stores window options for later open_win call.
--- Window not shown until :show() — caller can set keymaps on buffer before display.
---@param opts table|nil Window options: border, width, height, zindex, relative, row, col, style, noautocmd
---@return table Win instance with :show(), :focus(), :close(), :is_valid()
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
            style = opts.style or "testing",
            noautocmd = opts.noautocmd or true,
        },

        buffer = buf,
    }, M)
end

function M:is_valid()
    return self.win and vim.api.nvim_win_is_valid(self.win) or false
end

--- Opens the floating window. Sets local options (nofold, nowrap, noscrollbind).
--- Idempotent: no-op if already open.
--- Registers WinClosed autocmd to stop insert mode — caller can then re-focus elsewhere.
function M:show()
    if self:is_valid() then
        return
    end

    self.win = vim.api.nvim_open_win(self.buffer, true, self.win_opts)

    vim.api.nvim_set_option_value("foldenable", false, { scope = "local", win = self.win })
    vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = self.win })
    vim.api.nvim_set_option_value("scrollbind", false, { scope = "local", win = self.win })

    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(self.win),
        callback = function()
            vim.cmd("stopinsert")
        end,
        once = true
    })
end

function M:focus()
    if self:is_valid() then
        vim.api.nvim_set_current_win(self.win)
    end
end

function M:close()
    if not self:is_valid() then
        return
    end

    vim.api.nvim_win_close(self.win, true)
end

return M
