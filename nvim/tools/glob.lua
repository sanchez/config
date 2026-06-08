--- Glob tool. Wraps vim.fn.globpath for pattern-based file search. Filters directories by default (toggle via include_dirs).
return {
    description = "Finds files matching a glob pattern under the current working directory. Supports wildcards like **/*.lua or src/**/*.ts",
    inputs = {
        pattern = "Glob pattern to match, e.g. '**/*.lua' or 'src/**/*.ts'",
        _include_dirs = "Whether to include directories in results (boolean, default false)",
    },
    callback = function(inputs, history)
        local pattern = inputs.pattern
        history:add_debug_line(" -> Glob: " .. (pattern or ""))

        if not pattern then
            return tool_error("Missing pattern argument")
        end

        local cwd = vim.fn.getcwd()
        local matches = vim.fn.globpath(cwd, pattern, false, true)

        if not matches or #matches == 0 then
            return "No files matched pattern: " .. pattern
        end

        local include_dirs = inputs.include_dirs == "true" or inputs.include_dirs == true
        if not include_dirs then
            local filtered = {}
            for _, p in ipairs(matches) do
                if vim.fn.isdirectory(p) == 0 then
                    table.insert(filtered, p)
                end
            end
            matches = filtered
        end

        if #matches == 0 then
            return "No files matched pattern (after excluding directories): " .. pattern
        end

        return table.concat(matches, "\n")
    end,
}
