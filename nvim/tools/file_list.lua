return {
    description = "Lists all files in the current directory.",
    callback = function(inputs, history)
        history:add_debug_line(" -> Listing out all files")

        local dir = vim.fn.getcwd()

        if vim.fn.isdirectory(dir) == 0 then
            return tool_error("Error: directory not found: " .. dir)
        end

        local escaped = vim.fn.shellescape(dir)
        local cmd = string.format(
            "find %s -not -path '*/.git/*' -not -name '.git' 2>/dev/null | sort",
            escaped
        )

        local result = vim.fn.system(cmd)
        return result
    end,
}
