local Loader = require("packages.codehub.config_loader")
local Skills = require("packages.codehub.skills")

--- Directories supported for custom tools
local tools_dirs = {
    vim.fn.stdpath("config") .. "/tools",
    vim.fn.getcwd() .. "/.hub/tools",
}


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
    local resolved = vim.fs.resolve(abs_path)

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


function validate_path(path, arg_name)
    local ok, err = is_path_allowed(path, arg_name)
    if not ok then
        error(err)
    end
end


function tool_error(message)
    return { type = "error", message = message }
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


local function call_tool(history, name, inputs)
    for _, tool in pairs(tools) do
        if tool.name == name then
            local status, result = pcall(function()
                return tool.callback(inputs, history)
            end)

            if status then
                return result
            end

            error(result)
            return tool_error(result)
        end
    end

    error("Failed to find tool: " .. name)
    return tool_error("Failed to find tool")
end


return {
    tools = tools,
    call_tool = call_tool,
}
