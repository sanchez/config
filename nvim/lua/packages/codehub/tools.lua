--- Tool registry. Loads tool definitions from ~/.config/nvim/tools and .hub/tools.
--- Tools are .lua files returning {description, inputs, callback}. Built-in tool "load_skill" seeded before user tools.
--- Path validation: all file operations must resolve within cwd. Prevents ../ escapes.
--- File edit locking: same file can't be edited twice in one tool-call batch; LLM must process results first.
--- call_tool wraps tool.callback in pcall — returns error table on crash so LLM can self-correct.

local Loader = require("packages.codehub.config_loader")
local Skills = require("packages.codehub.skills")

--- Directories supported for custom tools
local tools_dirs = {
    vim.fn.stdpath("config") .. "/tools",
    vim.fn.getcwd() .. "/.hub/tools",
}

--- Security boundary: resolves path, verifies it's within cwd. Blocks symlink escapes via vim.fn.resolve.
---@param path string Requested path
---@param arg_name string Parameter name for error messages
---@return boolean, string|nil True if allowed, or false + error message
function is_path_allowed(path, arg_name)
    arg_name = arg_name or "path"

    if type(path) ~= "string" then
        return false, "Access denied: " .. arg_name .. " must be string"
    end

    local cwd = vim.fn.getcwd()
    if type(cwd) ~= "string" then
        return false, "Access denied: cannot determine working directory for " .. arg_name
    end

    local raw_abs = vim.fn.fnamemodify(path, ":p")
    if type(raw_abs) ~= "string" then
        return false, "Access denied: invalid path for " .. arg_name
    end

    raw_abs = raw_abs:gsub("(.+)/+$", "%1")
    local abs_path = vim.fs.normalize(raw_abs)
    local allowed = vim.fs.normalize(cwd)
    local resolved = vim.fn.resolve(abs_path)

    if type(resolved) ~= "string" then
        return false, "Access denied: path of " .. arg_name .. " resolution failed"
    end

    if resolved == allowed then
        return true
    end

    if resolved:sub(1, #allowed + 1) == allowed .. "/" then
        return true
    end

    return false, "Access denied: " .. arg_name .. " is outside the current nvim directory"
end

--- validate_path wrapper that throws on failure. Called by tool callbacks for early exit.
---@param path string
---@param arg_name string
function validate_path(path, arg_name)
    local ok, err = is_path_allowed(path, arg_name)
    if not ok then
        error(err)
    end
end

--- Convenience: returns standard error table for LLM consumption.
---@param message string Error description
---@return table { type = "error", message = message }
function tool_error(message)
    return { type = "error", message = message }
end

--- File edit lock: prevents same file being edited twice in one tool-call batch.
--- LLM must process the result of the first edit before issuing another to the same file.
local edited_files = {}

--- Checks if path is already locked from a prior edit in this batch. Locks it if not.
---@param path string Absolute file path
---@return string|nil Error message if locked, nil if lock acquired
function check_file_edit_lock(path)
    if edited_files[path] then
        return "Error: " .. path .. " was already edited in this batch. Process the result before editing the same file again."
    end
    edited_files[path] = true
end

--- Clears all file edit locks. Called by provider before processing a new batch of tool calls.
function clear_file_edit_locks()
    edited_files = {}
end

local tools = Loader.load_objects_from_paths(tools_dirs, {
    load_skill = {
        name = "load_skill",
        description = "Returns a skill's content based on provided name",
        inputs = {
            name = "Name of skill to load",
        },
        callback = function(inputs)
            return Skills.get_skill_content(inputs.name)
        end,
    },
})

--- Looks up tool by name and invokes callback. Wrapped in pcall: crashes return error table instead of breaking the loop.
---@param history table History instance (passed to tool for debug logging)
---@param name string Tool name
---@param inputs table Tool arguments
---@return any Tool result (string, table, or error table)
local function call_tool(history, name, inputs)
    for _, tool in pairs(tools) do
        if tool.name == name then
            local status, result = pcall(function()
                return tool.callback(inputs, history)
            end)

            if status then
                return result
            end

            return tool_error(result)
        end
    end

    print("Failed to find tool: " .. name)
    return tool_error("Failed to find tool")
end

return {
    tools = tools,
    call_tool = call_tool,
}