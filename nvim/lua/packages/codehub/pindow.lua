local M = {}
M.__index = M


local function win_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function buf_is_valid(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end


function M.new(title)
    local ns = vim.api.nvim_create_namespace("CodeHub_Pindow")

    local total_lines = vim.o.lines - vim.o.cmdheight
    local sidebar_width = math.max(28, math.floor(vim.o.columns * 0.25))
    local input_height = 1
    local gap = 0
    local output_height = total_lines - input_height - 2
    local column = vim.o.columns - sidebar_width

    local input_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[input_buf].buftype = "nofile"
    vim.bo[input_buf].bufhidden = "wipe"
    vim.bo[input_buf].swapfile = false
    vim.bo[input_buf].filetype = "CodeHubPindowInput"

    -- local input_win = vim.api.nvim_open_win(input_buf, true, {
    --     relative = "editor",
    --     row = 0,
    --     col = column,
    --     width = sidebar_width,
    --     height = input_height,
    --     style = "minimal",
    --     border = "single",
    --     title = " " .. title .. " ",
    --     title_pos = "center",
    -- })
    --
    -- vim.wo[input_win].wrap = false
    -- vim.wo[input_win].number = false
    -- vim.wo[input_win].relativenumber = false
    -- vim.wo[input_win].signcolumn = "no"
    -- vim.wo[input_win].cursorline = false

    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

    -- Right pinned vertical split
    vim.cmd("botright vertical " .. sidebar_width .. "split")
    local input_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(input_win, input_buf)

    local output_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[output_buf].buftype = "nofile"
    vim.bo[output_buf].bufhidden = "wipe"
    vim.bo[output_buf].swapfile = false
    vim.bo[output_buf].modifiable = false
    vim.bo[output_buf].filetype = "CodeHubPindowOutput"

    -- local output_win = vim.api.nvim_open_win(output_buf, false, {
    --     relative = "editor",
    --     row = input_height + gap + 1,
    --     col = column,
    --     width = sidebar_width,
    --     height = math.max(3, output_height),
    --     style = "minimal",
    --     border = "single",
    --     title = " Pindow ",
    --     title_pos = "left",
    -- })
    --
    -- vim.wo[output_win].wrap = false
    -- vim.wo[output_win].number = false
    -- vim.wo[output_win].relativenumber = false
    -- vim.wo[output_win].signcolumn = "no"
    -- vim.wo[output_win].cursorline = false

    -- Split the sidebar itself into top search + bottom list
    vim.cmd("belowright split")
    local output_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(output_win, output_buf)

    -- Go back to the top sidebar window and size it to 3 lines
    vim.api.nvim_set_current_win(input_win)
    vim.cmd("resize 3")

    -- Configure sidebar windows
    for _, win in ipairs({ input_win, output_win }) do
        vim.wo[win].number = false
        vim.wo[win].relativenumber = false
        vim.wo[win].signcolumn = "no"
        vim.wo[win].wrap = false
        vim.wo[win].cursorline = false
        vim.wo[win].winfixwidth = true
    end

    vim.wo[input_win].winfixheight = true

    vim.api.nvim_buf_set_name(input_buf, "CodeHubPindowInput")
    vim.api.nvim_buf_set_name(output_buf, "CodeHubPindowOutput")

    local function handle_input_changed()
    end

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = input_buf,
        callback = handle_input_changed
    })

    local function close()
        if win_is_valid(input_win) then
            vim.api.nvim_win_close(input_win, true)
        end

        if win_is_valid(output_win) then
            vim.api.nvim_win_close(output_win, true)
        end
    end

    vim.keymap.set({ "n", "i" }, "<Esc>", close, { buffer = input_buf, silent = true })
    vim.keymap.set("n", "<Esc>", close, { buffer = output_buf, silent = true })

    return setmetatable({
        ns = ns,

        -- input window details
        input_buf = input_buf,
        input_win = input_win,

        -- output window details
        output_buf = output_buf,
        output_win = output_win,
    }, M)
end


function M:close()
    if win_is_valid(self.input_win) then
        vim.api.nvim_win_close(self.input_win, true)
    end

    if win_is_valid(self.output_win) then
        vim.api.nvim_win_close(self.output_win, true)
    end
end

function M:render()
    if not buf_is_valid(self.output_buf) then
        return
    end

    vim.bo[self.output_buf].modifiable = true

    local lines = {}
    table.insert(lines, "Hello World")
    table.insert(lines, "TODO: Add more stuff here")

    vim.api.nvim_buf_set_lines(self.output_buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(self.output_buf, self.ns, 0, -1)

    vim.bo[self.output_buf].modifiable = false
end


function M:focus_input()
    if win_is_valid(self.input_win) then
        vim.api.nvim_set_current_win(self.input_win)
        vim.cmd("startinsert")
    end
end


function M:focus_output()
    if win_is_valid(self.output_win) then
        vim.api.nvim_set_current_win(self.output_win)
    end
end


return M
