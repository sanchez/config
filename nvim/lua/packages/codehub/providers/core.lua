local await = require("packages.core.async").await

--- HTTP client via vim.system(). Makes async requests with curl underneath.
local M = {}
M.__index = M

--- Makes HTTP request. Returns raw response body as string.
---@param method string HTTP method ("GET", "POST", etc.)
---@param url string Full URL
---@param headers table<string,string> Request headers
---@param opts table|nil Config with .data for body
---@return string|nil Response body or nil on failure
function M.create_request(method, url, headers, opts)
    return await(function(done)
        local arguments = {
            "curl", "-X", method, url,
        }

        for key, value in pairs(headers) do
            table.insert(arguments, "-H")
            table.insert(arguments, key .. ": " .. value)
        end

        local function callback(obj)
            vim.schedule(function()
                if obj.code == 0 then
                    done(obj.stdout)
                else
                    print(obj.stderr)
                    done(nil)
                end
            end)
        end

        if opts.data then
            table.insert(arguments, "-d")
            table.insert(arguments, "@-")

            local payload = vim.fn.json_encode(opts.data)
            vim.system(arguments, { text = true, stdin = payload }, callback)
        else
            vim.system(arguments, { text = true }, callback)
        end
    end)
end


function M.create_json_request(method, url, headers, opts)
    local data = M.create_request(method, url, headers, opts)
    if not data or data == vim.NIL then
        return nil
    end

    local res = vim.fn.json_decode(data)
    if res == vim.NIL then
        res = nil
    end

    return res
end


function M.fake_request()
    return await(function(done)
        vim.defer_fn(function()
            done(true)
        end, 1000)
    end)
end


return M
