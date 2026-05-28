local Tool = require("packages.codehub.tools.tool")

local skills = {}

local function parse_markdown_with_frontmatter(content)
    local frontmatter_str, body = content:match("^%-%-%-\n(.-)\n%-%-%-\n(.*)")

    if not frontmatter_str then
        return {}, content
    end

    local frontmatter_table = {}
    for line in frontmatter_str:gmatch("[^\r\n]+") do
        local key, value = line:match("^(%s*[^:]+)%s*:%s*(.*)%s*$")
        if key and value then
            key = key:gsub("^%s+", ""):gsub("%s+$", "")
            value = value:gsub("^%s*[\"']", ""):gsub("[\"']%s*$", "")
            frontmatter_table[key] = value
        end
    end

    return frontmatter_table, body
end

local function import_skill(name, path)
    if name:sub(-3) ~= ".md" then return end
    name = name:sub(1, -4)

    local lines = vim.fn.readfile(path)
    local raw_content = table.concat(lines, "\n")

    local frontmatter, content = parse_markdown_with_frontmatter(raw_content)

    skills[name] = {
        description = frontmatter.description,
        content = content
    }
end

local skills_dirs = {
    vim.fn.stdpath("config") .. "/skills",
    vim.fn.getcwd() .. "/skills",
}

for _, path in ipairs(skills_dirs) do
    pcall(function()
        local files = vim.fn.readdir(path)
        for _, file in ipairs(files) do
            import_skill(file, path .. "/" .. file)
        end
    end)
end


local load_skill = Tool.new({
    name = "load_skill",
    description = "Load the provided skill",
    inputs = {
        Tool.create_input("name", "Name of the skill to load", "string", true),
    },
    callback = function(history, inputs)
        history:add_debug_line(" -> Loading skill " .. inputs.name)

        local skill = skills[inputs.name]
        if skill == nil then
            return { type = "error", message = "Skill does not exist" }
        end

        return skill.content
    end,
})


return {
    skills = skills,
    load_skill = load_skill,
}
