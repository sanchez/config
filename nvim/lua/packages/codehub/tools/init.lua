local Tool = require("packages.codehub.tools.tool")


local get_time = Tool.new({
    name = "get_time",
    description = "Use to get the current system time",
    inputs = {},
    callback = function()
        return os.date("%Y-%m-%d %H:%M:%S")
    end
})


local get_cwd = Tool.new({
    name = "get_cwd",
    description = "Gets the current working directory",
    inputs = {},
    callback = function(history)
        history:add_debug_line(" -> Getting current working directory")
        return vim.fn.getcwd()
    end
})


local get_current_file = Tool.new({
    name = "get_current_file",
    description = "Gets the file path of the currently opened buffer in Neovim",
    inputs = {},
    callback = function(history)
        history:add_debug_line(" -> Getting current open file")

        local bufname = vim.fn.expand("%:p")
        if bufname == "" then
            return "No file is currently open"
        end
        return bufname
    end
})


local all_tools = {}
local function add_tools(tools)
    for _, tool in pairs(tools) do
        all_tools[tool.name] = tool
    end
end

add_tools({ get_time, get_cwd, get_current_file })
add_tools(require("packages.codehub.tools.file"))
add_tools(require("packages.codehub.tools.web"))
add_tools({ require("packages.codehub.tools.skills").load_skill })
add_tools(require("packages.codehub.tools.symbols"))

return all_tools
