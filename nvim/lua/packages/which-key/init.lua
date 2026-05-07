local View = {}
View.__index = View

function View:new(opts)
    opts = opts or {}
    local border = opts.border or "single"
    return setmetatable({
        border = border,
        width = opts.width or 40,
        height = opts.height or 10,
        zindex = opts.zindex or 1000,
    }, View)
end

function View:show(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local row = math.floor((vim.o.lines - self.height) / 2)
    local col = math.floor((vim.o.columns - self.width) / 2)

    local win_opts = {
        relative = "editor",
        width = self.width,
        height = self.height,
        row = row,
        col = col,
        style = "minimal",
        border = self.border,
        noautocmd = true,
        zindex = self.zindex,
    }

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    vim.api.nvim_win_set_option(win, "foldenable", false)
    vim.api.nvim_win_set_option(win, "wrap", false)
    vim.api.nvim_win_set_option(win, "scrollbind", false)

    return win, buf
end


vim.keymap.set('n', '<leader>?', function ()
    print("Running WhichKey")
    local view = View.new()
    view:show({"Hello Wrld"})
end)
