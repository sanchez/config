local Tool = require("packages.codehub.tools.tool")


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
        local start_row, _, end_row, _ = node:range()
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
            start_line = start_row + 1,  -- convert 0-indexed to 1-indexed
            end_line = end_row + 1,
        })
    end
    for child in node:iter_children() do
        collect_symbols(child, results)
    end
end


--- Returns all symbols (functions, classes, methods) with their line ranges.
---@type Tool
local get_document_symbols = Tool.new({
    name = "get_document_symbols",
    description = "Uses treesitter to extract all symbols (functions, methods, classes) and their start/end line numbers from a file. Returns a structured list.",
    inputs = {
        { name = "file_path", description = "Absolute path to the file to analyze", type = "string", is_required = true },
    },
    callback = function(history, inputs)
        local path = inputs.file_path
        history:add_debug_line(" -> Getting symbols for " .. (path or ""))

        if not path then
            return { type = "error", message = "Missing file_path argument" }
        end

        -- Load the file into a temporary buffer to run treesitter against it
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)

        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        if not ok or not parser then
            return { type = "error", message = "No treesitter parser available for: " .. path }
        end

        local tree = parser:parse()[1]
        if not tree then
            return { type = "error", message = "Failed to parse file: " .. path }
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
                "[%s] %s  (lines %d–%d)",
                sym.kind, sym.name, sym.start_line, sym.end_line
            ))
        end
        return table.concat(lines, "\n")
    end,
})


--- Queries LSP for workspace symbols matching a query string.
--- Requires an active LSP client that supports workspace/symbol.
local search_symbols = Tool.new({
    name = "search_symbols",
    description = "Searches for symbols (functions, classes, variables, etc.) across the entire workspace by name using LSP. Returns matching symbols with their file path and line number.",
    inputs = {
        { name = "query", description = "Symbol name or partial name to search for", type = "string", is_required = true },
    },
    callback = function(history, inputs)
        local query = inputs.query
        history:add_debug_line(" -> LSP workspace symbol search: " .. (query or ""))

        if not query then
            return { type = "error", message = "Missing query argument" }
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
})


--- Full-text search across the codebase using ripgrep.
local search_content = Tool.new({
    name = "search_content",
    description = "Searches for a text pattern across all files in the current working directory using ripgrep. Returns file path, line number, and matching line for each match.",
    inputs = {
        { name = "pattern",    description = "The text or regex pattern to search for",                             type = "string",  is_required = true },
        { name = "file_glob",  description = "Optional glob to restrict file types, e.g. '*.lua' or '*.ts'",       type = "string",  is_required = false },
        { name = "max_results", description = "Maximum number of results to return (default 50)",                   type = "number",  is_required = false },
    },
    callback = function(history, inputs)
        local pattern   = inputs.pattern
        local glob      = inputs.file_glob
        local max       = tonumber(inputs.max_results) or 50

        history:add_debug_line(" -> Searching codebase for: " .. (pattern or ""))

        if not pattern then
            return { type = "error", message = "Missing pattern argument" }
        end

        local cmd = string.format(
            "rg --line-number --no-heading --color=never -m %d %s %s 2>/dev/null",
            max,
            glob and ("--glob " .. vim.fn.shellescape(glob)) or "",
            vim.fn.shellescape(pattern)
        )

        local result = vim.fn.system(cmd)
        if result == "" then
            return "No matches found for: " .. pattern
        end
        return result
    end,
})


--- Finds files matching a glob pattern under the current working directory.
---@type Tool
local glob = Tool.new({
    name = "glob",
    description = "Finds files matching a glob pattern under the current working directory. Supports wildcards like **/*.lua or src/**/*.ts",
    inputs = {
        { name = "pattern", description = "Glob pattern to match, e.g. '**/*.lua' or 'src/**/*.ts'", type = "string", is_required = true },
        { name = "include_dirs", description = "Whether to include directories in results (default false)", type = "string", is_required = false },
    },
    callback = function(history, inputs)
        local pattern = inputs.pattern
        history:add_debug_line(" -> Glob: " .. (pattern or ""))

        if not pattern then
            return { type = "error", message = "Missing pattern argument" }
        end

        local cwd = vim.fn.getcwd()
        local matches = vim.fn.globpath(cwd, pattern, false, true)

        if not matches or #matches == 0 then
            return "No files matched pattern: " .. pattern
        end

        local include_dirs = inputs.include_dirs == "true" or inputs.include_dirs == true
        if not include_dirs then
            local filtered = {}
            for _, p in ipairs(matches) do
                if vim.fn.isdirectory(p) == 0 then
                    table.insert(filtered, p)
                end
            end
            matches = filtered
        end

        if #matches == 0 then
            return "No files matched pattern (after excluding directories): " .. pattern
        end

        return table.concat(matches, "\n")
    end,
})


return { 
    get_document_symbols = get_document_symbols,
    search_symbols = search_symbols,
    search_content = search_content,
    glob = glob,
}
