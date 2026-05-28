local await = require("packages.core.async").await

local M = {}
M.__index = M


function M.create_request(method, url, headers, opts)
    return await(function(done)
        local arguments = {
            "curl", "-X", method, url,
        }

        for key, value in pairs(headers) do
            table.insert(arguments, "-H")
            table.insert(arguments, key .. ": " .. value)
        end

        if opts.data then
            table.insert(arguments, "-d")
            table.insert(arguments, vim.fn.json_encode(opts.data))
        end

        vim.system(arguments, { text = true }, function(obj)
            vim.schedule(function()
                if obj.code == 0 then
                    done(obj.stdout)
                else
                    print(obj.stderr)
                    done(nil)
                end
            end)
        end)
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
