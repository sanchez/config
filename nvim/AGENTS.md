# Codebase Architecture

Neovim configuration with embedded AI coding assistant ("CodeHub"). Two layers: Neovim config modules and the CodeHub agent system.

## Module Map

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/                 # Neovim settings modules
│   │   ├── init.lua            # Loads all config modules
│   │   ├── color.lua           # Colorscheme
│   │   ├── editor.lua          # LSP, cmp, bufferline, lualine
│   │   ├── git.lua             # Git integration
│   │   ├── telescope.lua       # Telescope picker config
│   │   └── which.lua           # Which-key bindings
│   ├── packages/               # Plugin-like Lua packages
│   │   ├── core/               # Shared utilities
│   │   │   ├── async.lua       # Async/await via coroutines
│   │   │   ├── promptpopup.lua # Prompt popup UI
│   │   │   ├── vars.lua        # .env variable helpers
│   │   │   └── window.lua      # Window helpers
│   │   └── codehub/            # AI agent system
│   │       ├── init.lua        # Entry, keymaps (<leader>cc)
│   │       ├── agents/
│   │       │   ├── agent.lua   # Agent definition + system prompt loading
│   │       │   ├── history.lua # Session history, buffer rendering
│   │       │   └── init.lua    # Agent registry
│   │       ├── providers/      # API provider adapters
│   │       │   ├── core.lua    # HTTP utilities (curl wrapper)
│   │       │   ├── anthropic.lua # Anthropic API + tool handling
│   │       │   ├── openai.lua  # OpenAI API (stub)
│   │       │   ├── opencode.lua # OpenCode API
│   │       │   ├── fake.lua    # Fake provider for testing
│   │       │   └── init.lua    # Provider registry
│   │       ├── tools/          # Agent tools
│   │       │   ├── init.lua    # Tool registry + builtins
│   │       │   ├── tool.lua    # Tool base class
│   │       │   ├── file.lua    # File operations (read/write/edit/delete/list)
│   │       │   ├── web.lua     # Web search
│   │       │   └── skills.lua  # Skill loading from markdown
│   │       ├── pindow.lua      # Popup window (sidebar layout)
│   │       ├── display.lua     # Display helpers (Snacks-based)
│   │       └── message.lua     # Message handling
│   └── plugins/                # Plugin config
├── agents/                     # Agent system prompts (Markdown files)
├── skills/                     # Agent skills (Markdown + frontmatter)
└── .env                        # API keys, config
```

## CodeHub System Flow

```
<leader>cc -> Pindow.new() -> user input
                              |
                              v
                    history:add_message("user", input)
                              |
                              v
                    agent:execute(history)
                              |
                              v
                    provider(agent, history, tools)
                              |
                    +---------+---------+
                    |                   |
                    v                   v
            HTTP request            Tool calls
            (curl wrapper)          (file/web/etc)
                    |                   |
                    +---------+---------+
                              |
                              v
                    handle_response(history, tools, response)
                              |
                              v
                    history:add_message("assistant", ...)
```

## Provider Interface

Each provider is a function returned by `M.new(hostname, api_key, model_id)`:

```lua
provider(agent, history, tools) -> ()
```

- Loads system prompt from `agent.systemPrompt`
- Reads conversation from `history.history`
- Executes tools from `tools` table
- Appends assistant responses via `history:add_message("assistant", ...)`

## Tool Interface

Tools implement:

```lua
{
    name = "tool_name",
    description = "What the tool does",
    inputs = { { name, description, type, is_required } },
    callback = function(history, inputs) -> string
}
```

Path validation enforced via `is_path_allowed()` — agents can only access files under `vim.fn.getcwd()`.

---

# Coding Conventions

## Lua 5.1 (LuaJIT)

- No `continue` (use `if not x then ... end`)
- Tables as both arrays and dicts
- Coroutines for async via `async.exec()`
- Protected calls with `pcall()` for optional dependencies
- Result-or-message pattern: `nil` + error string on failure
- Concatenate with `..`, not `+`
- Iterate arrays with `ipairs()`, dicts with `pairs()`

## Module Pattern

```lua
local M = {}
M.__index = M

function M.new(...) ... end
function M:method(...) ... end

return M
```

Single-file modules with constructor + methods. No classes, no separate files per method. Constructor returns `setmetatable({...}, M)`.

## Factory Pattern

Providers and agents use factory pattern:

```lua
function M.new(hostname, api_key, model_id)
    return function(agent, history, tools)
        -- closure captures hostname, api_key, model_id
    end
end
```

`M.new()` returns a closure that captures configuration. Callers execute the returned function.

## Naming

- Modules: `snake_case.lua`
- Functions/Methods: `snake_case`
- Classes/Types: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private methods: prefixed `_` (e.g., `_update_footer`)
- Abbreviations: ok (`buf`, `fn`, `opts`, `cb`) but be consistent

## Error Handling

- `pcall()` wraps optional operations (file reads, directory checks)
- `vim.NIL` for RPC-compatible nil (distinct from Lua `nil`)
- Tool errors return error strings, never throw
- Provider errors propagate via `error()`
- `success, result = pcall(fn)` pattern for protected calls

## Async Pattern

```lua
local async = require("packages.core.async")

async.exec(function()
    local result = await(some_async_fn)
    -- code after await runs after promise resolves
end)
```

Uses coroutines to simulate async/await. `await()` suspends until promise completes. The `vim.system()` callback pattern with `vim.schedule()` is the underlying mechanism.

## Validation Pattern

Always validate inputs at function entry:

```lua
if type(path) ~= "string" then
    return false, "Access denied: invalid path type"
end
```

Return `false, error_message` for validation failures. Return just the value or `true` on success.

## Config Loading Pattern

```lua
local vars = require("packages.core.vars").get_vars()
local api_key = vars["OPENCODE_API_KEY"]
```

Load `.env` once via `vars.get_vars()`. Access with `vars["KEY"]`.

## Window/Buffer Validity

Always check validity before operating:

```lua
local function win_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end
```

Stale references become invalid after window closes.

## Neovim API Usage

- `vim.api.*` for all buffer/window/namespace operations
- `vim.bo[bufnr]` for buffer-local options
- `vim.wo[winid]` for window-local options
- `vim.fn.*` for Vim functions
- `vim.uv.*` for libUV (timers, fs events, networking)
- `vim.schedule()` to bridge uv callbacks to main event loop

## String Patterns

Lua patterns, not regex:
- `%d` for digits, `%D` for non-digits
- `%s` for whitespace, `%S` for non-whitespace
- `%w` for word characters
- `%b` for balanced pairs: `%b()` `%b""`
- Must escape magic chars: `gsub("([^%w])", "%%%1")`

---

# Brushstrokes

## Guard Clauses

Prefer early returns at function start:

```lua
if type(inputs) ~= "table" then
    return "Error: invalid inputs type"
end
```

Reduces nesting, clarifies failure modes.

## Optional Dependencies

```lua
pcall(function()
    local agentFile = agentsDir .. "/" .. name:lower() .. ".md"
    local systemPromptLines = vim.fn.readfile(agentFile)
    systemPrompt = systemPrompt .. table.concat(systemPromptLines, "\n")
end)
```

`pcall()` silently handles missing files. Pattern used for skill loading, agent files, env vars.

## Toggle Modifiable Pattern

```lua
vim.bo[self.buffer].modifiable = true
vim.api.nvim_buf_set_lines(...)
vim.bo[self.buffer].modifiable = false
```

Buffer must be `modifiable=true` before editing, `modifiable=false` after. Used in history buffer writes.

## Extmark Footer Pattern

```lua
vim.api.nvim_buf_set_extmark(buffer, ns, line_count - 1, 0, {
    virt_lines = footer_content,
    virt_lines_above = false
})
```

Replaces extmark each update to reposition footer. Delete old extmark first if `footer_extmark` is stored.

## Table.concat for Strings

```lua
table.concat(lines, "\n")
vim.fn.readfile(path) returns array of lines
```

Build large strings by concatenating tables, not repeated `..`.

## Format Helpers

```lua
local function format_token_number(num)
    if num > 1e9 then
        return string.format("%.2fb", num / 1e9)
    elseif num > 1e6 then
        return string.format("%.2fm", num / 1e6)
    end
    return tostring(num)
end
```

Abbreviate large numbers (tokens, cost).

## Closure for Cleanup

```lua
local closing = false
local function close()
    if closing then return end
    closing = true
    -- actual cleanup
end
```

Guard flag prevents double-close in event handlers.

## Tree Building with Recursion

```lua
function M:flatten(items, depth)
    table.insert(items, { message = self.message, level = depth })
    if self.expanded then
        for _, node in ipairs(self.nodes) do
            node:flatten(items, depth + 1)
        end
    end
    return items
end
```

Recursively build flat list from tree structure.

## Environment Variable Access

```lua
os.getenv("EXA_API_KEY")
```

Also check `vars.get_vars()` for `.env` values.

---

# Beware Of

## Path Restrictions

File tools (`read_file`, `write_file`, `edit_file`, `delete_file`, `list_files`) enforce `is_path_allowed()` — reject any path outside `vim.fn.getcwd()`. Security measure prevents agent from modifying config or system files.

## JSON Encoding

Uses `vim.fn.json_encode()` for API requests. Numbers become JSON numbers, strings must be explicit.

## Buffer State

History buffer created with `buftype=nofile`, `bufhidden=hide`. Must toggle `modifiable=true` before editing, `modifiable=false` after. Footer repositioned after each write via extmark.

## History Array vs Buffer

`history.history` stores raw API messages (role + content). Do NOT confuse with `history:add_message()` which writes to both history array AND buffer.

## Tool Call Loop

Anthropic provider loops until `send_again == false`. Each tool call adds result to history and triggers another API call. Risk of infinite loops if tool always returns unexpected format.

## Coroutine Context

`await()` cannot be called outside `async.exec()`. Common error: "await() cannot be called here."

## Vim.Schedule in Callbacks

When using `vim.system()` or `vim.uv.*` callbacks, wrap Neovim API calls in `vim.schedule()`:

```lua
vim.system(args, {}, function(obj)
    vim.schedule(function()
        -- vim.api calls here
    end)
end)
```

## Empty Tables

Empty table `{}` is truthy in Lua. Use `vim.tbl_isempty()` for dict emptiness.

## Module Caching

`require()` caches modules. Reload config clears `packages.*` and `loader.*` but not everything.

---

# Key System Goals

## Neovim as AI Coding Environment

Transform Neovim into an AI pair programming environment. Agent reads codebase, executes tools, edits files — all without leaving the editor.

## Multi-Provider Support

Abstract API providers behind common interface. Currently Anthropic primary, OpenAI/OpenCode stubs, Fake for testing.

## Tool-Based Agent Execution

Agent receives tools (file ops, web search, skill loading) rather than raw shell access. Path restrictions prevent misuse.

## Session Persistence

History buffer persists across interactions within session. `<leader>cd` resets. Agent selection persists.

## Extensible Skills

Skills loaded from Markdown files with YAML frontmatter. Skills describe capabilities the agent can invoke via `load_skill` tool.

## terse Communication

Agent response style: terse, technical, no filler. Use abbreviations. Strip articles. Pattern: `[thing] [action] [reason]. [next step].`
