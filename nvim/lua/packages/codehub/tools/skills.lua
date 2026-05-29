--- Skill loading from Markdown files with YAML frontmatter
--- Enables agents to invoke resuable capability docs via load_skill tool.
local Tool = require("packages.codehub.tools.tool")

--- Loaded skills registry. Key = skill name (filename without .md).
--- Value = { description, content }.
local skills = {}

--- Parses Markdown with optional YAML frontmatter (--- delimiters).
--- Returns frontmatter table and body content.
---@param content string Raw file content
---@return table, string Frontmatter dict + body text
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


--- Loads a single .md skill files into the skills registry.
--- Reads frontmatter (name/description) and body (content).
---@param name string Filename (must end in .md)
---@param path string Full path to file
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


--- Directories scanned for skills on startup
local skills_dirs = {
    vim.fn.stdpath("config") .. "/skills",
    vim.fn.getcwd() .. "/skills",
}


--- Scan skills_dirs and import all .md files.
for _, path in ipairs(skills_dirs) do
    pcall(function()
        local files = vim.fn.readdir(path)
        for _, file in ipairs(files) do
            import_skill(file, path .. "/" .. file)
        end
    end)
end


--- Tool: returns skill content for the agent. Triggers load_skill callback
---@type Tool
local load_skill = Tool.new({
    name = "load_skill",
    description = "Load the provided skill",
    inputs = {
        Tool.create_input("name", "Name of the skill to load", "string", true),
    },
    callback = function(history, inputs)
        history:add_debug_line(" -> Loading skill " .. inputs.name)
        if not inputs.name then
            return { type = "error", message = "Missing name parameter" }
        end

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
