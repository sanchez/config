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


function M:execute(inputs)
    local success, result = pcall(function()
        return self.callback(inputs)
    end)

    if success then
        return result
    else
        return { type = "error", message = result }
    end
end


return M
