--- Ripgrep search tool. Wraps `rg --line-number --no-heading --color=never`. Max results capped at 50.
--- Optional file_glob restricts file types (e.g. '*.lua'). _file_glob/_max_results are private params.
return {
    description = "Searches for a text pattern across all files in the current working directory using ripgrep. Returns filepath, line number, and matching line for each match.",
    inputs = {
        pattern = "The text or regex pattern to search for",
        _file_glob = "Optional glob to restrict file types, e.g. '*.lua', or '*.ts'",
        _max_results = "Maximum number of results to return (default 50)",
    },
    callback = function(inputs, history)
        local pattern = inputs.pattern
        local glob = inputs.file_glob
        local max = tonumber(inputs.max_results) or 50

        history:add_debug_line(" -> Searching codebase for: " .. (pattern or ""))

        if not pattern then
            return tool_error("Missing pattern argument")
        end

        local cmd = string.format(
            "rg --line-number --no-heading --color=never -m %d %s %s 2>/dev/null",
            max,
            glob and ("--glob " .. vim.fn.shellescape(glob)) or "",
            vim.fn.shellescape(pattern)
        )

        local result = vim.fn.system(cmd)
        if result == "" then
            return "No matches found for: " .. pattern
        end

        return result
    end,
}
