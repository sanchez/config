--- HTTP networking via curl + vim.system. Thin wrapper: no dependency on plenary or socket.
--- Two interfaces: create_request (raw text callback) and create_json_request (auto-decoded JSON callback).
--- Both run async — callback fires in vim.schedule for safe buffer/window access.
local M = {}
M.__index = M

--- Sends HTTP request via curl subprocess. POST with data pipes payload via stdin to avoid shell escaping issues.
--- Callback always fires in vim.schedule for Neovim API safety.
---@param method string "GET", "POST", etc.
---@param url string Full endpoint URL
---@param headers table<string,string> Header name→value map
---@param opts table|nil { data: table } — if present, JSON-encodes and sends via stdin
---@param callback fun(body: string|nil) Receives raw stdout (nil on error)
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

--- Convenience wrapper: JSON-decodes response before calling back. nil on parse failure.
---@param method string
---@param url string
---@param headers table<string,string>
---@param opts table|nil
---@param callback fun(decoded: table|nil)
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
