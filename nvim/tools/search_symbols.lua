--- LSP workspace symbol search. Sends workspace/symbol request to all attached clients, aggregates results.
--- Timeout 5000ms. Falls back to "No LSP results found" string if empty.
return {
    description = "Searches for symbols (functions, classes, variables, etc.) across the entire workspace by name using LSP. Returns matching symbols with their file path and line number.",
    inputs = {
        query = "Symbol name or partial name to search for",
    },
    callback = function(inputs, history)
        local query = inputs.query
        history:add_debug_line(" -> LSP workspace symbol search: " .. (query or ""))

        if not query then
            return tool_error("Missing query argument")
        end

        local results = vim.lsp.buf_request_sync(0, "workspace/symbol", { query = query }, 5000)
        if not results or vim.tbl_isempty(results) then
            return "No LSP results found for: " .. query
        end

        local lines = {}
        for _, client_result in pairs(results) do
            local symbols = client_result.result
            if symbols then
                for _, sym in ipairs(symbols) do
                    local loc = sym.location
                    local uri = loc and loc.uri or ""
                    local path = uri:gsub("^file://", "")
                    local line = loc and loc.range and (loc.range.start.line + 1) or 0
                    table.insert(lines, string.format("[%s] %s  %s:%d", sym.kind or "?", sym.name, path, line))
                end
            end
        end

        if #lines == 0 then
            return "No symbols found for: " .. query
        end
        return table.concat(lines, "\n")
    end,
}
