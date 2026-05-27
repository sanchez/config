local M = {}
M.__index = M


local function destructor(obj)
    vim.api.nvim_buf_delete(obj.buffer, { force = true })
end
M.__destructor = destructor


local function create_buffer()
    local ns = vim.api.nvim_create_namespace("CodeHub")

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].swapfile = false

    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buffer })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buffer })

    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Welcome to CodeHub, more details to come!", "" })
    vim.api.nvim_buf_set_extmark(buffer, ns, 0, 0, {
        line_hl_group = "Comment",
    })

    vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })

    return ns, buffer
end


function M.new(default_agent)
    local ns, buffer = create_buffer()

    local self = setmetatable({
        total_cost = 0,
        input_tokens = 0,
        output_tokens = 0,
        status = nil,
        agent = default_agent,

        ns = ns,
        buffer = buffer,
        footer_extmark = nil,

        history = {},
    }, M)

    self:_update_footer()
    return self
end


local function format_token_number(num)
    if num > 1e9 then
        return string.format("%.2fb", num / 1e9)
    elseif num > 1e6 then
        return string.format("%.2fm", num / 1e6)
    elseif num > 1e3 then
        return string.format("%.2fk", num / 1e3)
    end
    return tostring(num)
end


function M:_update_footer()
    local line_count = vim.api.nvim_buf_line_count(self.buffer)

    local status_message = "Unknown..."
    if self.status then
        status_message = self.status
    else
        status_message =
            "Agent: " .. self.agent ..
            " Cost: $" .. self.total_cost ..
            " I: " .. format_token_number(self.input_tokens) ..
            " O: " .. format_token_number(self.output_tokens)
    end

    -- metadata content 
    local footer_content = {
        { { "" } },
        { { status_message } },
    }

    if self.footer_extmark then
        vim.api.nvim_buf_del_extmark(self.buffer, self.ns, self.footer_extmark)
    end

    self.footer_extmark = vim.api.nvim_buf_set_extmark(self.buffer, self.ns, line_count - 1, 0, {
        virt_lines = footer_content,
        virt_lines_above = false -- place them below the line
    })
end


function M:_write_message(role, message)
    if role == "system" then return end

    local hl_map = {
        user = "Function",
        assistant = "Normal",
        details = "Comment",
        error = "Error",
    }

    vim.bo[self.buffer].modifiable = true

    local row = vim.api.nvim_buf_line_count(self.buffer)

    local messages = {}
    for line in (message .. "\n"):gmatch("(.-)\n") do
        table.insert(messages, line)
    end

    vim.api.nvim_buf_set_lines(self.buffer, -1, -1, false, messages)
    vim.api.nvim_buf_set_extmark(self.buffer, self.ns, row, 0, {
        end_row = row + #messages - 1,
        line_hl_group = hl_map[role],
    })

    -- reposition the footer to the new bottom
    self:_update_footer()

    -- auto-scroll to the bottom
    local win_ids = vim.fn.win_findbuf(self.buffer)
    for _, x in ipairs(win_ids) do
        vim.api.nvim_win_set_cursor(x, {
            vim.api.nvim_buf_line_count(self.buffer), 0
        })
    end

    vim.bo[self.buffer].modifiable = false
end


function M:add_debug_line(message)
    self:_write_message("details", message)
end


function M:add_error_line(message)
    self:_write_message("error", message)
end


function M:add_message(role, message)
    local role_options = {
        user = true,
        assistant = true,
        system = true,
    }

    if not role_options[role] then
        error(role .. " is not in list of supported roles")
    end

    table.insert(self.history, {
        role = role,
        content = message,
    })

    if type(message) == "string" then
        self:_write_message(role, message)
    end
end


function M:set_status(status)
    self.status = status
end

function M:add_costs(cost, input_tokens, output_tokens)
    self.total_cost = self.total_cost + cost
    self.input_tokens = self.input_tokens + input_tokens
    self.output_tokens = self.output_tokens + output_tokens
end


return M
