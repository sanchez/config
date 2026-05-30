--- Tool base class. Tools expose an interface the agent calls via tool.name.
local M = {}
M.__index = M

--- Helper: creates input spec dict for tool schema.
---@param name string Input parameter name
---@param description string Human-readable description
---@param type string JSON type ("string", "number", etc.)
---@param is_required boolean|nil Defaults to false
---@return table Input spec dict
function M.create_input(name, description, type, is_required)
    is_required = is_required or false
    return {
        name = name,
        description = description,
        type = type,
        is_required = is_required,
    }
end


--- Constructor. Creates tool with metadata and callback.
---@param opts table Tool config
---@param opts.name string Tool identifier (used in tool calls from LLM)
---@param opts.description string Human-readable description for the LLM
---@param opts.inputs table[] Array of input specs (from Tool.create_input)
---@param opts.outputs table Output spec (unused currently)
---@param opts.callback function(history, inputs) Tool implementation
---@return table Tool instance
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

--- Executes the tool with provided inputs. Wraps in pcall for safety.
--- Tool errors are caught, logged to history as error lines, returned as error blocks.
---@param history table History session (for error recording)
---@param inputs table Tool arguments from LLM
---@return any Tool result or { type = "error", message }
function M:execute(history, inputs)
    local success, result = pcall(function()
        return self.callback(history, inputs or {})
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
