local M = {}
M.__index = M


function M.create_input(name, description, type, is_required)
    is_required = is_required or false
    return {
        name = name,
        description = description,
        type = type,
        is_required = is_required,
    }
end


function M.new(opts)
    opts = opts or {}

    return setmetatable({
        name = opts.name,
        description = opts.description,
        inputs = opts.inputs,
        outputs = opts.outputs,
        callback = opts.callback,
    }, M)
end


function M:execute(history, inputs)
    local success, result = pcall(function()
        return self.callback(history, inputs)
    end)

    if success then
        return result
    else
        local str_result = result
        if type(str_result) ~= "string" then
            str_result = vim.inspect(str_result)
        end

        history:add_error_line(str_result)
        return { type = "error", message = result }
    end
end


return M
