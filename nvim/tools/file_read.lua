--- File read tool. Reads file line-by-line with optional start/end bounds. Truncates at 2000 lines to limit context.
--- _start_line and _end_line are private (underscore prefix) — not required in tool call schema.
return {
    description = "Reads a file from the local filesystem and return its contents",
    inputs = {
        file_path = "The absolute path to the file to read",
        _start_line = "The line number to start reading from (1-indexed, optional, defaults to 1)",
        _end_line = "The line number to stop reading at (1-indexed, inclusive, optional, defaults to end of file)",
    },
    callback = function(inputs, history)
        local path = inputs.file_path
        history:add_debug_line(" -> Reading file " .. (path or ""))

        validate_path(path, "file_path")

        local start_line = tonumber(inputs.start_line) or 1
        local end_line = tonumber(inputs.end_line)

        if start_line < 1 or start_line ~= math.floor(start_line) then
            return tool_error("Error: start_line must be a positive integer")
        end

        if end_line and (end_line < 1 or end_line ~= math.floor(end_line)) then
            return tool_error("Error: end_line must be a positive integer")
        end

        if end_line and end_line < start_line then
            return tool_error("Error: end_line must be >= start_line")
        end

        local f = io.open(path, "r")
        if not f then
            return tool_error("Error: file not found or cannot be read: " .. path)
        end

        local lines = {}
        local line_num = 0
        local truncated = false

        for line in f:lines() do
            line_num = line_num + 1
            if line_num >= start_line then
                if #lines >= 2000 then
                    truncated = true
                    break
                end

                table.insert(lines, line)

                if end_line and line_num >= end_line then
                    break
                end
            end
        end
        f:close()

        if line_num < start_line then
            return "Error: start_line(" .. start_line .. ") exceeds file length (" .. line_num .. "): " .. path
        end

        local result = table.concat(lines, "\n")

        if truncated then
            result = result .. "\n\n... [TRUNCATED: read limit of 2000 lines reached. Use start_line/end_line to read remaining lines.]"
        end

        return result
    end,
}
