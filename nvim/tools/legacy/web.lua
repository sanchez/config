--- Web search/fetch via Exa API. Provides websearch + webfetch as Tool instances (legacy Tool.new pattern).
--- Requires EXA_API_KEY in .env. Note: references packages.core.async (may not exist — verify before use).
--- Currently unused in main CodeHub flow; kept as reference implementation for external API tools.
local Tool = require("packages.codehub.tools.tool")
local await = require("packages.core.async").await
local vars = require("packages.core.vars")

local API_BASE = "https://api.exa.ai"

--- Reads EXA_API_KEY from .env first, falls back to environment variable.
---@return string|nil API key or nil if not set
local function get_api_key()
    local env_vars = vars.get_vars()
    return env_vars["EXA_API_KEY"] or os.getenv("EXA_API_KEY")
end

--- Fires async POST to Exa endpoint with API key header.
---@param endpoint string API path (e.g. "/search")
---@param params table Request body params
---@return table|string Parsed JSON response or error string
local function exa_api(endpoint, params)
    local api_key = get_api_key()
    if not api_key then
        return "Error: EXA_API_KEY not set. Add it to ~/.config/nvim/.env"
    end

    local raw = await(function(done)
        local data = vim.fn.json_encode(params)
        local args = {
            "curl", "-s", "-X", "POST",
            API_BASE .. endpoint,
            "-H", "x-api-key: " .. api_key,
            "-H", "Content-Type: application/json",
            "-d", data,
        }
        vim.system(args, { text = true }, function(obj)
            vim.schedule(function()
                if obj.code == 0 then
                    done(obj.stdout)
                else
                    done(nil)
                end
            end)
        end)
    end)

    if not raw then
        return "Error: Exa API request failed"
    end

    local ok, decoded = pcall(vim.fn.json_decode, raw)
    if not ok or decoded == vim.NIL then
        return "Error: Failed to parse API response"
    end

    if decoded.error then
        return "Error: " .. (decoded.error.message or vim.inspect(decoded.error))
    end

    return decoded
end

--- Splits comma-separated string into trimmed array. Strips empty entries.
---@param str string|nil CSV string
---@return string[]|nil Array of non-empty trimmed strings
local function split_csv(str)
    if not str or str == "" then
        return nil
    end
    local result = {}
    for part in str:gmatch("[^,]+") do
        local trimmed = part:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(result, trimmed)
        end
    end
    if #result == 0 then
        return nil
    end
    return result
end

--- Formats search result list: numbered titles + URLs + highlights + date.
---@param result table|string API result or error string
---@return string Formatted multi-line result summary
local function format_search_results(result)
    if type(result) == "string" then
        return result
    end

    if not result.results or #result.results == 0 then
        return "No results found."
    end

    local lines = {}
    for i, r in ipairs(result.results) do
        table.insert(lines, string.format("%d. %s", i, r.title or "Untitled"))
        table.insert(lines, "   URL: " .. (r.url or "N/A"))
        if r.highlights and #r.highlights > 0 then
            for _, h in ipairs(r.highlights) do
                table.insert(lines, "   > " .. h)
            end
        end
        if r.publishedDate then
            table.insert(lines, "   Published: " .. r.publishedDate)
        end
        table.insert(lines, "")
    end
    return table.concat(lines, "\n")
end

--- Formats single URL fetch result: best text available or highlights.
---@param result table|string API result or error string
---@return string Extracted text content
local function format_fetch_result(result)
    if type(result) == "string" then
        return result
    end

    if not result.results or #result.results == 0 then
        return "No content found for the URL."
    end

    local r = result.results[1]
    if r.text then
        return r.text
    end

    if r.highlights and #r.highlights > 0 then
        return table.concat(r.highlights, "\n")
    end

    return vim.inspect(r)
end

--- Web search tool. Returns results with URLs, titles, highlights.
---@type Tool
local websearch = Tool.new({
    name = "websearch",
    description = "Performs a web search using the Exa API. Returns results with URLs, titles, and highlights.",
    inputs = {
        Tool.create_input("query", "The search query string", "string", true),
        Tool.create_input("type", "Search type: auto, fast, instant, deep-lite, deep, deep-reasoning", "string", false),
        Tool.create_input("num_results", "Number of results to return (default 10, max 25)", "number", false),
        Tool.create_input("include_domains", "Comma-separated domains to restrict results to", "string", false),
        Tool.create_input("exclude_domains", "Comma-separated domains to exclude", "string", false),
        Tool.create_input("max_age_hours", "Max age of cached content in hours (0=live, -1=never livecrawl)", "number", false),
    },
    callback = function(history, inputs)
        history:add_debug_line(" -> Search the web for '" .. inputs.query .. "'")

        local params = {
            query = inputs.query,
            type = inputs.type or "auto",
            numResults = tonumber(inputs.num_results) or 10,
            contents = {
                highlights = true,
            },
        }

        local include_domains = split_csv(inputs.include_domains)
        if include_domains then
            params.includeDomains = include_domains
        end

        local exclude_domains = split_csv(inputs.exclude_domains)
        if exclude_domains then
            params.excludeDomains = exclude_domains
        end

        if inputs.max_age_hours then
            params.contents.maxAgeHours = tonumber(inputs.max_age_hours)
        end

        local result = exa_api("/search", params)
        return format_search_results(result)
    end
})

--- Fetches and extracts clean text from a URL.
---@type Tool
local webfetch = Tool.new({
    name = "webfetch",
    description = "Fetches and extracts clean text content from a URL using the Exa API.",
    inputs = {
        Tool.create_input("url", "The URL to fetch content from", "string", true),
        Tool.create_input("max_age_hours", "Max age of cached content in hours (0=live crawl)", "number", false),
    },
    callback = function(history, inputs)
        history:add_debug_line(" -> Web Fetching " .. inputs.url)
        local params = {
            urls = { inputs.url },
            text = { maxCharacters = 20000 },
        }

        if inputs.max_age_hours then
            params.maxAgeHours = tonumber(inputs.max_age_hours)
        end

        local result = exa_api("/contents", params)
        return format_fetch_result(result)
    end
})

return {
    websearch = websearch,
    webfetch = webfetch,
}
