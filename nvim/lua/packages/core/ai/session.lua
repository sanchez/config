local M = {}
M.__index = M


local function destructor(obj)
    print("Destructor")
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


function M.new(endpoint_func, tools)
    tools = tools or {}

    local ns, buffer = create_buffer()

    return setmetatable({
        history = {},
        tools = tools,
        endpoint_func = endpoint_func,
        total_cost = 0,
        input_tokens = 0,
        output_tokens = 0,

        ns = ns,
        buffer = buffer,
        window = nil,
        footer_extmark = nil,

        is_thinking = false,
    }, M)
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
    if self.is_thinking then
        status_message = "Thinking..."
    else
        status_message = 
            "Cost: $" .. self.total_cost ..
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
    if role == "system" then
        return
    end

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


function M:add_message(role, message, write_message)
    if write_message == nil then
        write_message = true
    end

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

    if write_message then
        self:_write_message(role, message)
    end
end


function M:call_tool(name, inputs)
    for _, tool in ipairs(self.tools) do
        if tool.name == name then
            return tool:execute(inputs)
        end
    end

    return { type = "error", message = "Failed to find tool" }
end


function M:add_costs(cost, input_tokens, output_tokens)
    self.total_cost = self.total_cost + cost
    self.input_tokens = self.input_tokens + input_tokens
    self.output_tokens = self.output_tokens + output_tokens
end


function M:execute()
    if self.is_thinking then
        return
    end
    self.is_thinking = true
    self:_update_footer()

    self.endpoint_func(self)

    self.is_thinking = false
    self:_update_footer()
end


function M:debug()
    for _, message in ipairs(self.history) do
        print(message.role .. ": " .. message.content)
    end
end

return M
