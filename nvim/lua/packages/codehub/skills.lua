--- Skill registry. Loads skill definitions from ~/.config/nvim/skills and .hub/skills.
--- Skills are markdown documents — content injected as system prompt for context-aware assistance.
--- get_skill_content used by load_skill built-in tool.

local Loader = require("packages.codehub.config_loader")


--- Directories supported for skills
local skills_dirs = {
    vim.fn.stdpath("config") .. "/skills",
    vim.fn.getcwd() .. "/.hub/skills",
}


local skills = Loader.load_objects_from_paths(skills_dirs)


local function get_skill_content(name)
    for _, skill in pairs(skills) do
        if skill.name == name then
            return skill.content
        end
    end

    return { type = "error", message = "Failed to find skill" }
end


return {
    skills = skills,
    get_skill_content = get_skill_content,
}
