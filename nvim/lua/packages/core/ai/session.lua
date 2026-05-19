local M = {}
M.__index = M


local function destructor(obj)
    print("Destructor")
    vim.api.nvim_buf_delete(obj.buffer, { force = true })
end
M.__destructor = destructor


local function create_buffer()
    local ns = vim.api.nvim_create_namespace("CodeHub")

    vim.api.nvim_set_hl(ns, "user", { fg = "#5ef1ff", bold = true })
    vim.api.nvim_set_hl(ns, "assistant", { fg = "#ff5ef1", bold = true })
    vim.api.nvim_set_hl(ns, "details", { fg = "#888888", italic = true })

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].modifiable = false

    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buffer })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buffer })

    -- vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })

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


function M:_update_footer()
    local line_count = vim.api.nvim_buf_line_count(self.buffer)

    -- metadata content
    local footer_content = {
        "",
        "Type /msg <user> to whisper..."
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

    vim.bo[self.buffer].modifiable = false

    local last_line = vim.api.nvim_buf_line_count(self.buffer)

    -- insert the new message
    vim.api.nvim_buf_set_lines(self.buffer, -1, -1, false, { message })

    -- style the new message
    vim.api.nvim_buf_set_extmark(self.buffer, self.ns, last_line, 0, {
        end_row = last_line,
        end_col = #message,
        hl_group = role,
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

    vim.bo[self.buffer].modifiable = true
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

    self:write_message(role, message)
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

    self.endpoint_func(self)

    self.is_thinking = false
end


function M:debug()
    for _, message in ipairs(self.history) do
        print(message.role .. ": " .. message.content)
    end
end

return M
