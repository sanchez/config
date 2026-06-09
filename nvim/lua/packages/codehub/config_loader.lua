local M = {}
M.__index = M


local function handle_lua_file(path)
    local obj = dofile(path)
    if type(obj) == "function" then
        return { callback = obj }
    end

    return obj
end


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
