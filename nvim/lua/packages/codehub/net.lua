local M = {}
M.__index = M


function M.create_request(method, url, headers, opts, callback)
    local arguments = {
        "curl", "-X", method, url,
    }

    for key, value in pairs(headers) do
        table.insert(arguments, "-H")
        table.insert(arguments, key .. ": " .. value)
    end

    local function handle_response(obj)
        vim.schedule(function()
            if obj.code == 0 then
                callback(obj.stdout)
            else
                print(obj.stderr)
                callback(nil)
            end
        end)
    end

    if opts.data then
        table.insert(arguments, "-d")
        table.insert(arguments, "@-")

        local payload = vim.fn.json_encode(opts.data)
        vim.system(arguments, { text = true, stdin = payload }, handle_response)
    else
        vim.system(arguments, { text = true }, handle_response)
    end
end


function M.create_json_request(method, url, headers, opts, callback)
    M.create_request(method, url, headers, opts, function(data)
        if not data or data == vim.NIL then
            return callback(nil)
        end

        local res = vim.fn.json_decode(data)
        if res == vim.NIL then
            res = nil
        end

        callback(res)
    end)
end


return M
