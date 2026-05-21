local M = {}
M.__index = M


local function win_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function buf_is_valid(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end

local function create_buffers()
    local input_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[input_buf].buftype = "nofile"
    vim.bo[input_buf].bufhidden = "wipe"
    vim.bo[input_buf].swapfile = false
    -- vim.bo[input_buf].filetype = "CodeHubPindowInput"

    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

    return input_buf
end


local function create_windows(ns, sidebar_width, input_buf, output_buf)
    -- Right pinned vertical split
    vim.cmd("botright vertical " .. sidebar_width .. "split")
    local output_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(output_win, output_buf)
    vim.api.nvim_win_set_hl_ns(output_win, ns)

    -- Split the sidebar itself into top list + bottom text
    vim.cmd("belowright split")
    local input_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(input_win, input_buf)

    -- Resize to 3 lines
    vim.cmd("resize 3")

    -- Configure sidebar windows
    -- for _, win in ipairs({ input_win, output_win }) do
    --     vim.wo[win].number = false
    --     vim.wo[win].relativenumber = false
    --     vim.wo[win].signcolumn = "no"
    --     vim.wo[win].wrap = false
    --     vim.wo[win].cursorline = false
    --     vim.wo[win].winfixwidth = true
    -- end

    vim.wo[input_win].winfixheight = true

    return input_win, output_win
end


function M.new(title, ns, output_buf, callback)
    local ns = vim.api.nvim_create_namespace("CodeHub_Pindow")

    local total_lines = vim.o.lines - vim.o.cmdheight
    local sidebar_width = math.max(56, math.floor(vim.o.columns * 0.25))
    local input_height = 1
    local gap = 0
    local output_height = total_lines - input_height - 2
    local column = vim.o.columns - sidebar_width

    local input_buf = create_buffers()
    local input_win, output_win = create_windows(ns, sidebar_width, input_buf, output_buf)

    vim.keymap.set("n", "<CR>", function()
        local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
        local finalText = table.concat(lines, "\n")
        vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })
        callback(finalText)
    end, { buffer = input_buf })

    local closing = false
    local function close()
        if closing then
            return
        end
        closing = true

        if win_is_valid(input_win) then
            vim.api.nvim_win_close(input_win, true)
        end

        if win_is_valid(output_win) then
            vim.api.nvim_win_close(output_win, true)
        end
    end

    vim.api.nvim_create_autocmd("WinClosed", {
        callback = function(args)
            local closed = tonumber(args.match)
            if closed == input_win or closed == output_win then
                vim.schedule(close)
            end
        end,
    })

    vim.keymap.set("n", "<Esc>", close, { buffer = input_buf, silent = true })
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

function M:render(lines)
    if not buf_is_valid(self.output_buf) then
        return
    end

    vim.bo[self.output_buf].modifiable = true

    if #lines == 0 then
        lines = { "" }
    end

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
