local Tool = require("packages.codehub.tools.tool")


local get_time = Tool.new({
    name = "get_time",
    description = "Use to get the current system time",
    inputs = {},
    callback = function(inputs)
        return os.date("%Y-%m-%d %H:%M:%S")
    end
})


return {
    get_time = get_time
}
