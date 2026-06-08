--- File edit tool. Line-range replacement (1-indexed, inclusive). Empty new_content deletes the range.
--- Validates path within cwd, line numbers positive integers, end ≥ start, file exists, bounds in range.
return {
    description = "Replaces lines start_line through end_line (1-indexed, inclusive) with new_content. Provide empty new_content to delete the range.",
    inputs = {
        file_path = "The absolute path to the file to edit",
        start_line = "File line to replace (1-indexed)",
        end_line = "Last line to replace (1-indexed, inclusive)",
        new_content = "The text to insert in place of the range. Can be multi-line. Empty string deletes the range.",
    },
    callback = function(inputs, history)
        local path = inputs.file_path
        history:add_debug_line(" -> Editing file " .. (path or ""))

        validate_path(path, "file_path")

        local start_line = tonumber(inputs.start_line)
        local end_line = tonumber(inputs.end_line)
        local new_content = inputs.new_content

        if not start_line or start_line < 1 or start_line ~= math.floor(start_line) then
            return tool_error("Error: start_line must be a positive integer")
        end

        if not end_line or end_line < 1 or end_line ~= math.floor(end_line) then
            return tool_error("Error: end_line must be a positive integer")
        end

        if end_line < start_line then
            return tool_error("Error: end_line must be >= start_line")
        end

        if type(new_content) ~= "string" then
            return tool_error("Error: new_content must be a string")
        end

        local f = io.open(path, "r")
        if not f then
            return tool_error("Error: file not found or cannot be read: " .. path)
        end

        local lines = {}
        for line in f:lines() do
            table.insert(lines, line)
        end
        f:close()

        if start_line > #lines then
            return tool_error("Error: start_line (" .. start_line .. ") exceeds file length (" .. #lines .. "): " .. path)
        end

        if end_line > #lines then
            return tool_error("Error: end_line (" .. end_line .. ") exceeds file length (" .. #lines .. "): " .. path)
        end

        -- Build new line array: keep lines before range, insert new_content, keep lines after range
        local result = {}
        for i = 1, start_line - 1 do
            table.insert(result, lines[i])
        end

        if new_content ~= "" then
            for line in (new_content .. "\n"):gmatch("(.-)\n") do
                table.insert(result, line)
            end
        end

        for i = end_line + 1, #lines do
            table.insert(result, lines[i])
        end

        f = io.open(path, "w")
        if not f then
            return tool_error("Error: cannot write file: " .. path)
        end
        f:write(table.concat(result, "\n"))
        f:close()

        return "File edited successfully: " .. path
    end,
}
