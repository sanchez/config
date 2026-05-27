local Tool = require("packages.codehub.tools.tool")


local read_file = Tool.new({
    name = "read_file",
    description = "Reads a file from the local filesystem and returns its contents",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to read", type = "string", is_required = true },
        { name = "offset", description = "The line number to start reading from (optional)", type = "number", is_required = false },
        { name = "limit", description = "The maximum number of lines to read (optional)", type = "number", is_required = false },
    },
    callback = function(inputs)
        local path = inputs.file_path
        local f = io.open(path, "r")
        if not f then
            return "Error: file not found or cannot be read: " .. path
        end
        local lines = {}
        local offset = tonumber(inputs.offset) or 1
        local limit = tonumber(inputs.limit)
        local line_num = 0
        for line in f:lines() do
            line_num = line_num + 1
            if line_num >= offset then
                table.insert(lines, line)
                if limit and #lines >= limit then
                    break
                end
            end
        end
        f:close()
        return table.concat(lines, "\n")
    end
})


local write_file = Tool.new({
    name = "write_file",
    description = "Writes or creates a file at the given path with the given content",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to write", type = "string", is_required = true },
        { name = "content", description = "The content to write to the file", type = "string", is_required = true },
    },
    callback = function(inputs)
        local path = inputs.file_path
        local content = inputs.content
        local f, err = io.open(path, "w")
        if not f then
            return "Error: cannot write file: " .. path .. " (" .. (err or "unknown error") .. ")"
        end
        f:write(content)
        f:close()
        return "File written successfully: " .. path
    end
})


local edit_file = Tool.new({
    name = "edit_file",
    description = "Applies a partial edit to a file by replacing old_string with new_string. The old_string must match exactly one occurrence in the file.",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to edit", type = "string", is_required = true },
        { name = "old_string", description = "The text to replace", type = "string", is_required = true },
        { name = "new_string", description = "The text to replace it with", type = "string", is_required = true },
    },
    callback = function(inputs)
        local path = inputs.file_path
        local old_str = inputs.old_string
        local new_str = inputs.new_string

        local f = io.open(path, "r")
        if not f then
            return "Error: file not found or cannot be read: " .. path
        end
        local original = f:read("*a")
        f:close()

        local count = 0
        local _ = original:gsub(old_str:gsub("([^%w])", "%%%1"), function() count = count + 1 end)

        if count == 0 then
            return "Error: old_string not found in file: " .. path
        end
        if count > 1 then
            return "Error: old_string found " .. count .. " times in file, must match exactly once: " .. path
        end

        local modified = original:gsub(old_str:gsub("([^%w])", "%%%1"), new_str, 1)
        f = io.open(path, "w")
        if not f then
            return "Error: cannot write file: " .. path
        end
        f:write(modified)
        f:close()
        return "File edited successfully: " .. path
    end
})


local list_files = Tool.new({
    name = "list_files",
    description = "Lists all files in a directory tree view. Optionally specify a root directory and max depth.",
    inputs = {
        { name = "dir_path", description = "The root directory to list (defaults to current working directory)", type = "string", is_required = false },
        { name = "max_depth", description = "Maximum directory depth to traverse (default: 3)", type = "number", is_required = false },
    },
    callback = function(inputs)
        local dir = inputs.dir_path or vim.fn.getcwd()
        local max_depth = tonumber(inputs.max_depth) or 3
        if vim.fn.isdirectory(dir) == 0 then
            return "Error: directory not found: " .. dir
        end
        local escaped = vim.fn.shellescape(dir)
        local cmd = string.format(
            "find %s -maxdepth %d -not -path '*/.git/*' -not -name '.git' 2>/dev/null | sort",
            escaped, max_depth
        )
        return vim.fn.system(cmd)
    end
})

return {
    read_file = read_file,
    write_file = write_file,
    edit_file = edit_file,
    list_files = list_files,
}
