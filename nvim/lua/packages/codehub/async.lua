-- https://gist.github.com/vurentjie/566a7158038ea6e044a4321c63cacde0

---@vararg function
---@return any
local function await(...)
    local ok, main = coroutine.running()

    if not ok or main then
        error("Error: await() cannot be called here.")
    end

    local args = {...}

    if #args == 0 then
        error("Error: await() expects a function.")
    end

    if #args == 1 then
        assert(type(args[1]) == "function", string.format("Not a function: %s", args[1]))
        return coroutine.yield(args[1])
    end

    return coroutine.yield(function(done)
        local results = {}
        local count = #args
        local accumulate = function(index, vals)
            results[index] = vals
            count = count - 1
            if count == 0 then
                done(unpack(results))
            end
        end
        for idx, fn in ipairs(args) do
            assert(type(fn) == "function", string.format("Not a function: %s", fn))
            fn(function(...)
                accumulate(idx, {...})
            end)
        end
    end)
end

---@param callback fun(await: fun(done: fun(any...)))
--- Wraps callback in coroutine. Callback receives await fn; call it to yield until done.
local function exec(callback)
    local co = coroutine.create(function()
        callback(await)
    end)

    local done = nil
    done = function(...)
        local success, fn = coroutine.resume(co, ...)
        if fn == vim.NIL then
            fn = nil
        end
        assert(success, fn)
        if coroutine.status(co) ~= "dead" then
            fn(done)
        end
    end
    done()
end

return {
    exec = exec,
    await = await
}
