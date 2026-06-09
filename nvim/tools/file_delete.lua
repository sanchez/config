return {
    description = "Deletes a file from the local filesystem",
    inputs = {
        file_path = "The absolute path to the file to delete",
    },
    callback = function(inputs, history)
        local path = inputs.file_path
        history:add_debug_line(" -> Deleting file " .. (path or ""))

        validate_path(path, "file_path")

        local f = io.open(path, "r")
        if not f then
            return tool_error("Error: file not found: " .. path)
        end
        f:close()

        local success, err_msg = os.remove(path)
        if not success then
            return tool_error("Error: cannot delete file: " .. path .. " (" .. (err_msg or "unknown error") .. ")")
        end

        return "File deleted successfully: " .. path
    end,
}
