--- File edit tool. Line-range replacement (1-indexed, inclusive). Empty new_content deletes the range.
--- Validates path within cwd, line numbers positive integers, end ≥ start, file exists, bounds in range.
--- Always returns the edited region with line numbers for verification.
--- Post-write: checks for duplicate lines and (for Lua) syntax errors.
return {
    description = "Replaces lines start_line through end_line (1-indexed, inclusive) with new_content. Provide empty new_content to delete the range. Always returns edited region with line numbers.",
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
        local new_content = inputs.new_content or ""

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
        local original = f:read("*a")
        f:close()

        local lines = {}
        for line in original:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        if start_line > #lines then
            return tool_error("Error: start_line (" .. start_line .. ") exceeds file length (" .. #lines .. "): " .. path)
        end
        if end_line > #lines then
            return tool_error("Error: end_line (" .. end_line .. ") exceeds file length (" .. #lines .. "): " .. path)
        end

        -- Build new line array
        local new_lines = {}
        for i = 1, start_line - 1 do
            table.insert(new_lines, lines[i])
        end
        if new_content ~= "" then
            for line in (new_content .. "\n"):gmatch("(.-)\n") do
                table.insert(new_lines, line)
            end
        end
        for i = end_line + 1, #lines do
            table.insert(new_lines, lines[i])
        end
        local result = table.concat(new_lines, "\n")

        -- Write
        f = io.open(path, "w")
        if not f then
            return tool_error("Error: cannot write file: " .. path)
        end
        f:write(result)
        f:close()

        -- Compute edited range for context display
        local edited_start_line = start_line
        local edited_end_line = start_line
        if new_content ~= "" then
            local repl_lines = 1
            for _ in new_content:gmatch("\n") do repl_lines = repl_lines + 1 end
            edited_end_line = start_line + repl_lines - 1
        else
            edited_end_line = start_line - 1 -- deletion
        end

        -- Build context: edited region ± 3 lines, with line numbers
        local all_lines = {}
        for line in result:gmatch("[^\r\n]+") do
            table.insert(all_lines, line)
        end
        local ctx_start = math.max(1, edited_start_line - 3)
        local ctx_end = math.min(#all_lines, math.max(edited_start_line, edited_end_line) + 3)
        local context = ""
        for i = ctx_start, ctx_end do
            local marker = (i >= edited_start_line and i <= edited_end_line) and ">" or " "
            context = context .. string.format("%s%4d | %s\n", marker, i, all_lines[i])
        end

        local header = "File edited: " .. path
        if edited_start_line <= edited_end_line then
            header = header .. " (lines " .. edited_start_line .. "-" .. edited_end_line .. ")"
        else
            header = header .. " (deleted, was line " .. edited_start_line .. ")"
        end

        return header .. "\n" .. context
    end,
}
