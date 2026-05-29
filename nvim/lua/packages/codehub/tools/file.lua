--- File operation tools: read, write, edit, delete, list.
--- All paths validated against cwd is_path_allowed()
local Tool = require("packages.codehub.tools.tool")


--- Security: prevents agent from accessing files outside nvim cwd.
--- Resolves symlinks to catch path traversal attempts.
---@param path string Relative or absolute path
---@return boolean, string|nil Allowed + error on failure
local function is_path_allowed(path)
    if type(path) ~= "string" then
        return false, "Access denied: invalid path type"
    end

    local cwd = vim.fn.getcwd()
    if type(cwd) ~= "string" then
        return false, "Access denied: cannot determine working directory"
    end

    local raw_abs = vim.fn.fnamemodify(path, ":p")
    if type(raw_abs) ~= "string" then
        return false, "Access denied: invalid path"
    end

    raw_abs = raw_abs:gsub("(.+)/+$", "%1")
    local abs_path = vim.fs.normalize(raw_abs)
    local allowed = vim.fs.normalize(cwd)
    local resolved = vim.fn.resolve(abs_path)

    if type(resolved) ~= "string" then
        return false, "Access denied: path resolution failed"
    end

    if resolved == allowed then
        return true
    end
    if resolved:sub(1, #allowed + 1) == allowed .. "/" then
        return true
    end

    return false, "Access denied: path is outside the current nvim directory"
end

--- Validates path and returns err tuple. Fail-fast helper for tool callbacks.
---@param path string Path to validate
---@return boolean, string|nil Allowed + error message
local function validate_path(path)
    if not is_path_allowed(path) then
        return false, "Access denied: path is outside the current nvim directory"
    end
    return true, nil
end


--- Reads file contents. Supports offset + limit for partial reads.
---@type Tool
local read_file = Tool.new({
    name = "read_file",
    description = "Reads a file from the local filesystem and returns its contents",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to read", type = "string", is_required = true },
        { name = "offset", description = "The line number to start reading from (optional)", type = "number", is_required = false },
        { name = "limit", description = "The maximum number of lines to read (optional)", type = "number", is_required = false },
    },
    callback = function(history, inputs)
        if type(inputs) ~= "table" then
            return "Error: invalid inputs type"
        end

        local path = inputs.file_path
        history:add_debug_line(" -> Reading file " .. (path or ""))
        if path == nil then
            return { type = "error", message = "Missing path argument" }
        end

        local ok, err = validate_path(path)
        if not ok then
            return err
        end

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


--- Writes or creates file. Overwrites existing content entirely.
---@type Tool
local write_file = Tool.new({
    name = "write_file",
    description = "Writes or creates a file at the given path with the given content",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to write", type = "string", is_required = true },
        { name = "content", description = "The content to write to the file", type = "string", is_required = true },
    },
    callback = function(history, inputs)
        if type(inputs) ~= "table" then
            return "Error: invalid inputs type"
        end

        local path = inputs.file_path
        history:add_debug_line(" -> Writing file " .. (path or ""))
        if path == nil then
            return { type = "error", message = "Missing path argument" }
        end
        local content = inputs.content

        if type(content) ~= "string" and type(content) ~= "number" then
            return "Error: content must be a string or number"
        end

        local ok, err = validate_path(path)
        if not ok then
            return err
        end

        local f, err_msg = io.open(path, "w")
        if not f then
            return "Error: cannot write file: " .. path .. " (" .. (err_msg or "unknown error") .. ")"
        end
        f:write(content)
        f:close()
        return "File written successfully: " .. path
    end
})


--- Replaces one occurrence of old_string with new_string.
--- Errors if old_string missing or matchs multiple times.
---@type Tool
local edit_file = Tool.new({
    name = "edit_file",
    description = "Applies a partial edit to a file by replacing old_string with new_string. The old_string must match exactly one occurrence in the file.",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to edit", type = "string", is_required = true },
        { name = "old_string", description = "The text to replace", type = "string", is_required = true },
        { name = "new_string", description = "The text to replace it with", type = "string", is_required = true },
    },
    callback = function(history, inputs)
        if type(inputs) ~= "table" then
            return "Error: invalid inputs type"
        end

        local path = inputs.file_path
        history:add_debug_line(" -> Editing file " .. (path or ""))
        if path == nil then
            return { type = "error", message = "Missing path argument" }
        end

        local ok, err = validate_path(path)
        if not ok then
            return err
        end

        local old_str = inputs.old_string
        local new_str = inputs.new_string

        if type(old_str) ~= "string" then
            return "Error: old_string must be a string"
        end
        if type(new_str) ~= "string" then
            return "Error: new_string must be a string"
        end

        local f = io.open(path, "r")
        if not f then
            return "Error: file not found or cannot be read: " .. path
        end
        local original = f:read("*a")
        f:close()

        if type(original) ~= "string" then
            return "Error: failed to read file: " .. path
        end

        local count = 0
        local escaped = old_str:gsub("([^%w])", "%%%1")
        local _ = original:gsub(escaped, function() count = count + 1 end)

        if count == 0 then
            return "Error: old_string not found in file: " .. path
        end
        if count > 1 then
            return "Error: old_string found " .. count .. " times in file, must match exactly once: " .. path
        end

        local modified = original:gsub(escaped, new_str, 1)
        f = io.open(path, "w")
        if not f then
            return "Error: cannot write file: " .. path
        end
        f:write(modified)
        f:close()
        return "File edited successfully: " .. path
    end
})


--- Recursively lists all files under cwd (excludes .git).
---@type Tool
local list_files = Tool.new({
    name = "list_files",
    description = "Lists all files the current directory.",
    callback = function(history)
        history:add_debug_line(" -> Listing out all files")

        local dir = vim.fn.getcwd()

        local ok, err = validate_path(dir)
        if not ok then
            return err
        end

        if vim.fn.isdirectory(dir) == 0 then
            return "Error: directory not found: " .. dir
        end
        local escaped = vim.fn.shellescape(dir)
        local cmd = string.format(
            "find %s -not -path '*/.git/*' -not -name '.git' 2>/dev/null | sort",
            escaped
        )

        local result = vim.fn.system(cmd)
        return result
    end
})


--- Deletes a file by path. Errors if file doesn't exist or is protected.
---@type Tool
local delete_file = Tool.new({
    name = "delete_file",
    description = "Deletes a file from the local filesystem",
    inputs = {
        { name = "file_path", description = "The absolute path to the file to delete", type = "string", is_required = true },
    },
    callback = function(history, inputs)
        if type(inputs) ~= "table" then
            return "Error: invalid inputs type"
        end

        local path = inputs.file_path
        history:add_debug_line(" -> Deleting file " .. (path or ""))
        if path == nil then
            return { type = "error", message = "Missing path argument" }
        end

        if type(path) ~= "string" then
            return "Error: file_path must be a string"
        end

        local ok, err = validate_path(path)
        if not ok then
            return err
        end

        local f = io.open(path, "r")
        if not f then
            return "Error: file not found: " .. path
        end
        f:close()

        local success, err_msg = os.remove(path)
        if success then
            return "File deleted successfully: " .. path
        else
            return "Error: cannot delete file: " .. path .. " (" .. (err_msg or "unknown error") .. ")"
        end
    end
})


return {
    read_file = read_file,
    write_file = write_file,
    edit_file = edit_file,
    list_files = list_files,
    delete_file = delete_file,
}
