--- File write/create tool. Opens file in "w" mode (creates or overwrites). Validates path within cwd first.
return {
    description = "Writes or creates a file at the given path with the given content",
    inputs = {
        file_path = "The absolute path to the file to write",
        content = "The content to write to the file",
    },
    callback = function(inputs, history)
        local path = inputs.file_path
        history:add_debug_line(" -> Writing file " .. (path or ""))
        validate_path(path, "file_path")

        local content = inputs.content
        if type(content) ~= "string" and type(content) ~= "number" then
            return tool_error("Error: content must be a string or number")
        end

        local f, err_msg = io.open(path, "w")
        if not f then
            return tool_error("Error: cannot write file: " .. path .. " (" .. (err_msg or "unknown error") .. ")")
        end

        f:write(content)
        f:close()

        return "File written successfully: " .. path
    end,
}
