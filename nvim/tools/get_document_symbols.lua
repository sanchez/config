--- Node kinds to extract as "symbols" (tune to taste)
local SYMBOL_KINDS = {
    ["function"] = true,
    ["method_definition"] = true,
    ["local_function"] = true,
    ["function_definition"] = true,
    ["function_declaration"] = true,
    ["class_definition"] = true,
    ["class_declaration"] = true,
}

--- Walks a treesitter tree and collects symbol nodes.
---@param node userdata TSNode root
---@param results table Accumulator
local function collect_symbols(node, results)
    local kind = node:type()
    if SYMBOL_KINDS[kind] then
        local start_row, _, end_row, _ = node.range()

        -- Try to get the symbol name from first named child (usually the identifier)
        local name = "<anonymous>"
        for child in node:iter_children() do
            if child:named() and child:type():find("name") or child:type() == "identifier" then
                name = vim.treesitter.get_node_text(child, 0)
                break
            end
        end

        table.insert(results, {
            name = name,
            kind = kind,
            start_line = start_row + 1, -- convert 0-indexed to 1-indexed
            end_line = end_row + 1,
        })
    end

    for child in node:iter_children() do
        collect_symbols(child, results)
    end
end

return {
    description = "Uses treesitter to extract all symbols (functions, methods, classes) and their start/end line numbers from a file. Returns a structured list.",
    inputs = {
        file_path = "Absolute path to the file to analyze",
    },
    callback = function(inputs, history)
        local path = inputs.file_path
        history:add_debug_line(" -> Getting symbols for " .. (path or ""))

        if not path then
            return tool_error("Missing file_path argument")
        end

        validate_path(path, "file_path")

        -- Load the file into a temporary buffer to run treesitter against it
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)

        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        if not ok or not parser then
            return tool_error("No treesitter parser available for: " .. path)
        end

        local tree = parser:parse()[1]
        if not tree then
            return tool_error("Failed to parse file: " .. path)
        end

        local results = {}
        collect_symbols(tree:root(), results)

        if #results == 0 then
            return "No symbols found in: " .. path
        end

        -- Format as a readable string for the LLM
        local lines = {}
        for _, sym in ipairs(results) do
            table.insert(lines, string.format(
                "[%s] %s  (lines %d-%d)",
                sym.kind, sym.name, sym.start_line, sym.end_line
            ))
        end

        return table.concat(lines, "\n")
    end,
}
