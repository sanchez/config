# Coding Conventions

## Documentation Style

Every file starts with `---` docstring describing **what** the file contains, **why** it exists, and its role in the system. Not what each function does — that's for inline comments. File docstrings are architectural signposts.

```lua
--- File read tool. Reads file line-by-line with optional start/end bounds. Truncates at 2000 lines to limit context.
--- _start_line and _end_line are private (underscore prefix) — not required in tool call schema.
```

Functions have `---@param` / `---@return` annotations. Inline comments explain **why** not **what**.
```lua
-- History messages may be nested {content = {role, content}}; unwrap to clean {role, content} for API
```

## Module Pattern

All modules use the `local M = {}; M.__index = M` + `setmetatable` OOP pattern. No class libraries. Constructors return `setmetatable({...}, M)`. Methods use `:` syntax.

```lua
local M = {}
M.__index = M

function M.new(opts)
    return setmetatable({
        field = opts.field or default,
    }, M)
end

function M:method()
    -- use self
end

return M
```

## Table-of-Tuples for Repetitive Calls

When many `vim.keymap.set` calls share the same pattern, they're declared as a table of tuples and iterated:

```lua
local keybinds = {
    { "<leader>sg", Snacks.picker.grep, "Grep" },
    { "<leader>sb", Snacks.picker.lines, "Buffer Lines" },
    -- ...
}
for _, x in ipairs(keybinds) do
    vim.keymap.set("n", x[1], function() x[2]() end, { desc = x[3] })
end
```

## Spacing & Layout

- **No blank lines between module-local functions** — compact clustering of related logic
- **Single blank line** separates the `local M = {}` header from first function
- **No blank line before `return M`** — return glued to last function
- **No trailing whitespace**
- **Comments use `--` not `---` for inline; `---` reserved for docstrings**
- **Multi-line tables:** each field on its own line unless the table is trivially small (1-2 fields). Closing `}` on its own line.
- **Function bodies:** first line after `function` is never blank. Logic starts immediately.

## Naming

- **Private functions/vars:** no underscore prefix convention at file scope. Underscore prefix (`_start_line`) used for tool inputs that should be hidden from the LLM's required-params schema.
- **`M`** for module table (not `mod`, not `module`).
- **`opts`** for options tables (not `options`, not `config`).
- **`buf`/`win`/`ns`** for Neovim buffer/window/namespace handles.
- **Files:** lowercase, snake_case. `commandwindow.lua` not `commandWindow.lua`.

## Error Handling

- **pcall for tool callbacks** — tools must never crash the provider loop. Errors become structured `{type="error", message=...}` tables.
- **pcall for config loading** — `.env` parsing wrapped in pcall, failure notified via `vim.notify`.
- **validate_path throws** — file-operation tools call `validate_path` which `error()`s on invalid path. That error is caught by the pcall in `call_tool`.
- **Retry logic** — provider has 1 retry on nil/error response with 1000ms delay.
- **No exceptions for expected failures** — `is_path_allowed` returns `bool, err_msg`; caller decides to throw or propagate.

## Closure / Callback Patterns

- **Callback always last argument** — `function make_request(agent, history, callback)`.
- **Callback fires in vim.schedule** when touching Neovim API from async context (`net.lua`).
- **done() callbacks** — async utilities use `done(...)` convention for coroutine resume.

## Lua-isms

- `vim.fn.*` for Vimscript functions (not `vim.call` unless needed)
- `vim.api.nvim_*` for Neovim API (not vim.cmd strings for API operations)
- String formatting: `string.format` for structured output, `..` concatenation for simple joins
- `vim.inspect` for debug printing, `vim.notify` for user-facing messages
- Tables as maps: `for key, value in pairs(tbl)` always used; `ipairs` only when index order matters

## Defensive Neovim Patterns

- **`vim.bo[buf].modifiable = true/false`** — toggle before/after every buffer write, restore immediately
- **`pcall` around `node:range()` / `node:type()`** — some treesitter nodes don't support these
- **WinClosed autocmd with re-entrancy guard** — `pindow.lua` uses `closing` flag to prevent double-close
- **`vim.schedule` for deferred cleanup** — WinClosed fires inside window close; defer actual close to avoid re-entry

# Key System Goals

1. **AI-native Neovim:** CodeHub is the primary interface for AI-assisted coding. Pindow (<leader>cc) is the main entry point — type, hit Enter, get LLM responses with tool execution.

2. **Extensible tool/agent/provider system:** Everything is loaded from directories. Projects can define `.hub/` overrides for project-specific agents, tools, providers, and skills. No editing of global config needed.

3. **Safety-first file operations:** All tool file access is cwd-bounded. Path traversal blocked. This is the security invariant — the LLM can only touch files within the project it's assisting.

4. **Minimal dependencies:** HTTP via curl subprocess, not plenary. Async via coroutines, not external libs. The framework is self-contained within `packages/codehub/`.

5. **Fast, modal editing experience:** Flash.nvim for jump, Snacks.picker for fuzzy finding, Blink.cmp for completion. Leader-key namespace organized: `<leader>s` = search, `<leader>f` = file, `g` = LSP, `<leader>c` = CodeHub.

6. **Single-machine, single-user config:** This is a personal Neovim config. No multi-user concerns. No cross-platform abstractions. Hardcoded for the author's preferences (Catppuccin Frappe, 4-space indent, jj to escape, relative line numbers).
