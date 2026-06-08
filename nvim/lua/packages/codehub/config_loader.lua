--- Generic object loader. Reads directories of .lua and .md files, parses them into name-keyed tables.
--- .lua files: executed via dofile, expects return of table or function (function → {callback = fn}).
--- .md files: YAML frontmatter extracted as key-value pairs, body returned as .content.
--- Multiple paths merged: later paths override earlier ones by name (shallow merge).
local M = {}
M.__index = M

--- Loads a .lua file. If return value is a function, wraps as {callback = fn} for uniform interface.
---@param path string Absolute file path
---@return table|nil Parsed object or nil on failure
local function handle_lua_file(path)
    local obj = dofile(path)
    if type(obj) == "function" then
        return { callback = obj }
    end

    return obj
end

--- Parses a markdown file. Extracts YAML frontmatter (between --- delimiters) as key-value pairs.
--- Body (everything after frontmatter) stored as .content. No YAML library — simple colon-separated key:value parsing.
---@param path string Absolute file path
---@return table|nil Parsed object with .content, .name, plus frontmatter keys
local function handle_markdown_file(path)
    local lines = vim.fn.readfile(path)
    local raw_content = table.concat(lines, "\n")

    local frontmatter_str, body = raw_content:match("^%-%-%-\n(.-)\n%-%-%-\n(.*)")
    frontmatter_str = frontmatter_str or ""
    local obj = {}
    for line in frontmatter_str:gmatch("[^\r\n]+") do
        local key, value = line:match("^(%s*[^:]+)%s*:%s*(.*)%s*$")
        if key and value then
            key = key:gsub("^%s+", ""):gsub("%s+$", "")
            value = value:gsub("^%s*[\"']", ""):gsub("[\"']%s*$", "")
            obj[key] = value
        end
    end

    obj.content = body or raw_content

    return obj
end

--- Dispatches to correct handler based on file extension. Sets .name from filename stem.
---@param path string Absolute file path
---@return table|nil Parsed object or nil if extension unsupported
local function handle_load_file(path)
    local filename = vim.fs.basename(path)
    local extension = vim.fn.fnamemodify(filename, ":e")
    local name = vim.fn.fnamemodify(filename, ":t:r")

    local obj = nil

    if extension == "lua" then
        obj = handle_lua_file(path)
    elseif extension == "md" then
        obj = handle_markdown_file(path)
    end

    if obj ~= nil then
        obj.name = name
    end

    return obj
end

--- Loads all supported files from a single directory. Skips non-files silently.
---@param path string Directory path
---@return table[] Array of parsed objects
local function load_objects_from_path(path)
    if vim.fn.isdirectory(path) ~= 1 then
        return {}
    end

    local items = {}

    local files = vim.fn.readdir(path)
    for _, file in ipairs(files) do
        local obj = handle_load_file(path .. "/" .. file)
        if obj then
            table.insert(items, obj)
        end
    end

    return items
end

--- Shallow merge: b's non-nil fields overwrite a's. Used to combine same-name objects across paths.
---@param a table|nil Base object
---@param b table|nil Override object
---@return table Merged result
local function merge_objects(a, b)
    a = a or {}
    b = b or {}

    for key, value in pairs(b) do
        if value ~= nil then
            a[key] = b[key]
        end
    end

    return a
end

--- Public API. Loads objects from multiple directory paths, merges by name.
--- Later paths override earlier ones. Existing table can be seeded (e.g. built-in tools before user tools).
---@param paths string[] Directories to scan
---@param existing table|nil Pre-populated name→object map
---@return table Name→object dictionary
function M.load_objects_from_paths(paths, existing)
    local result = existing or {}

    for _, path in ipairs(paths) do
        local items = load_objects_from_path(path)
        for _, item in ipairs(items) do
            result[item.name] = merge_objects(result[item.name], item)
        end
    end

    return result
end

return M
