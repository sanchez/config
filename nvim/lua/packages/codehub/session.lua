--- Session persistence for CodeHub. Saves/restores chat history to .hub/session.json per project.
--- Auto-saves on VimLeavePre if session has messages. Restores on first <leader>cc.
local M = {}

local function session_path()
    return vim.fn.getcwd() .. "/.hub/session.json"
end

function M.exists()
    return vim.fn.filereadable(session_path()) == 1
end

function M.save(data)
    local dir = vim.fn.getcwd() .. "/.hub"
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    local f = io.open(session_path(), "w")
    if not f then return end
    f:write(vim.fn.json_encode(data))
    f:close()
end

function M.load()
    if not M.exists() then return nil end
    local f = io.open(session_path(), "r")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()
    local ok, data = pcall(vim.fn.json_decode, raw)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

function M.delete()
    if M.exists() then
        vim.fn.delete(session_path())
    end
end

return M
