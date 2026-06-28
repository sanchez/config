--- File edit tool. Line-range replacement (1-indexed, inclusive). Empty new_content deletes the range.
--- Validates path within cwd, line numbers positive integers, end ≥ start, file exists, bounds in range.
--- Uses f:lines() for reading (preserves empty lines, consistent with file_read). Splits new_content
--- via vim.split which preserves trailing newlines (e.g. "a\nb\n" → {"a","b",""}).
--- Rejects edit if same file was already edited in this tool-call batch (lock via check_file_edit_lock).
--- Always returns the edited region with line numbers for verification.
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

        -- Reject if this file was already edited in the current batch
        local lock_err = check_file_edit_lock(path)
        if lock_err then
            return tool_error(lock_err)
        end
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

        -- Read file with f:lines() to preserve empty lines (consistent with file_read tool)
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
        -- Split new_content into lines preserving empties. vim.split handles trailing \n correctly
        -- (e.g. "a\nb\n" → {"a","b",""}, "a\nb" → {"a","b"}).
        local nc = new_content:gsub("\r\n", "\n"):gsub("\r", "\n")
        local repl_lines = {}
        if nc ~= "" then
            repl_lines = vim.split(nc, "\n", { plain = true })
        end

        -- Build new line array: keep before-range, insert replacement, keep after-range
        local new_lines = {}
        for i = 1, start_line - 1 do
            table.insert(new_lines, lines[i])
        end
        for _, line in ipairs(repl_lines) do
            table.insert(new_lines, line)
        end
        for i = end_line + 1, #lines do
            table.insert(new_lines, lines[i])
        end

        -- Write
        f = io.open(path, "w")
        if not f then
            return tool_error("Error: cannot write file: " .. path)
        end
        f:write(table.concat(new_lines, "\n"))
        f:close()

        -- Compute edited range for context display (use actual repl_lines count)
        local edited_start_line = start_line
        local edited_end_line
        if #repl_lines > 0 then
            edited_end_line = start_line + #repl_lines - 1
        else
            edited_end_line = start_line - 1 -- deletion
        end

        -- Build context from new_lines (avoids re-parsing written file)
        local ctx_start = math.max(1, edited_start_line - 3)
        local ctx_end = math.min(#new_lines, math.max(edited_start_line, edited_end_line) + 3)
        local context = ""
        for i = ctx_start, ctx_end do
            local marker = (i >= edited_start_line and i <= edited_end_line) and ">" or " "
            context = context .. string.format("%s%4d | %s\n", marker, i, new_lines[i])
        end

        local header = "File edited: " .. path
        if #repl_lines > 0 then
            header = header .. " (lines " .. edited_start_line .. "-" .. edited_end_line .. ")"
        else
            header = header .. " (deleted, was line " .. edited_start_line .. ")"
        end

        return header .. "\n" .. context
    end,
}