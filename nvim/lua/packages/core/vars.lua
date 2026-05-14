local M = {}
M.__index = M

-- local loadedConfig = nil

local function loadConfig()
    local currentConfig = {}

    local configDir = vim.fn.stdpath("config")
    local envLocation = configDir .. "/.env"

    local lines = vim.fn.readfile(envLocation)
    for _, line in ipairs(lines) do
        -- trim whitespace
        line = line:match("^%s*(.-)%s*$")

        -- skip blanks and comments
        if line ~= "" and not line:match("^#") then
            -- support: KEY=VALUE
            local key, value = line:match("^([%a_][%w_]*)%s*=%s*(.-)%s*$")
            if key then
                -- remove surrounding quotes
                if value:match('^".*"$') or value:match("^'.*'$") then
                    value = value:sub(2, -2)
                end
                currentConfig[key] = value
            end
        end


        -- local key = string.match(line, "^([^=]+)")
        -- local value = string.match(line, "=(.+)$")
        -- currentConfig[key] = value
    end

    return currentConfig
end

function M.get_vars()
    local c = {}
    local success, err = pcall(function()
        c = loadConfig()
    end)

    if not success then
        vim.notify(vim.inspect(err), "error")
        print(vim.inspect(err))
    end

    return c
end

return M
