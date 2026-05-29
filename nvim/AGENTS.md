# Codebase Architecture

Neovim config (`~/.config/nvim`) with built-in AI coding assistant ("CodeHub"). Stack: **Lua 5.1/LuaJIT**, **Neovim API**, **snacks.nvim** for UI, **blink.cmp** for completion, **plenary.nvim** for utilities. Uses `vim.pack.add()` for plugin management (not lazy.nvim).

## On-disk map

```
init.lua                     # Entry: vim opts, keymaps, loads config + loader
lua/
  loader.lua                 # require("packages.codehub")
  config/
    init.lua                 # Plugin specs + keymaps (snacks, flash, blink.lib, fidget)
    editor.lua               # LSP + bufferline + lualine + blink.cmp setup
    color.lua                # catppuccin-frappe colorscheme
    git.lua                  # lazygit.nvim integration
    telescope.lua            # telescope finders (find_files, live_grep, buffers, help_tags)
    which.lua                # which-key.nvim setup (helix preset)
  packages/
    core/
      async.lua              # Coroutine-based async: exec(fn), await(fn) pattern
      vars.lua               # .env file parser (KEY=VALUE, quotes, # comments)
      window.lua             # Floating window factory (Win class)
      promptpopup.lua        # Single-line cursor-anchored input popup
    codehub/
      init.lua               # Keymaps: <leader>cc (open), <leader>ca (pick agent), <leader>cd (reset)
      pindow.lua             # Right-sidebar popup: input (3 lines) + output buffer
      win.lua                # Simple floating window factory (legacy, used by CommandWindow)
      display.lua            # Snacks-based message display (legacy, unused by current flow)
      message.lua            # Collapsible message tree node
      commandwindow.lua      # Cursor-anchored overlay wrapper around Win
      agents/
        init.lua             # Agent registry: Plan, Research, Build. Exports shared history.
        agent.lua            # Agent factory: loads system prompt from agents/*.md + cwd/AGENTS.md + skills
        history.lua          # Session buffer: messages, token/cost tracking, footer status bar
      providers/
        init.lua             # Provider registry (openai, anthropic, fake)
        core.lua             # HTTP client via vim.system + curl; create_request, create_json_request
        anthropic.lua        # Anthropic API provider: /zen/go/v1/messages, thinking, tool_use loop, retries
        openai.lua           # OpenAI API provider: /zen/go/v1/chat/completions, tool_calls loop, retries
        opencode.lua         # OpenCode model listing helper (GET /zen/go/v1/models)
        fake.lua             # Test provider: simulates agent loop with hardcoded tool calls + delays
      tools/
        init.lua             # Tool registry: get_time, get_cwd, get_current_file + file/web/skills tools
        tool.lua             # Tool base class: schema, execute() with pcall safety
        file.lua             # File ops: read, write, edit, delete, list_files. Path sandbox (cwd-gated).
        web.lua              # Exa API: websearch + webfetch tools
        skills.lua           # Skill loader: parses .md with YAML frontmatter from skills/ dirs
  plugins/
    opencode.lua             # opencode.nvim plugin spec + render-markdown dependency
    tree.lua                 # nvim-tree plugin spec (lazy=false)
agents/
  build.md                   # System prompt for Build agent (coding conventions + glossary)
skills/
  nvim_lua.md                # Neovim Lua guide (vim.api, vim.fn, vim.opt, etc.)
  create-skill.md            # How to create skill files
  agents-md.md               # AGENTS.md format spec
.env                         # API keys: OPENCODE_API_KEY, EXA_API_KEY
```

## Key modules & seams

### Agent system (`codehub/agents/`)
- **Agent** = name + systemPrompt + provider closure + tool list
- System prompt constructed from: `agents/{name}.md` + `cwd/AGENTS.md` + auto-generated skills listing
- **History** = session buffer with message log, token/cost accumulator, footer status bar. Rendered to a `nofile` buffer with role-based highlighting (user=Function, assistant=Normal, details=Comment, error=Error)
- Agent registry creates 3 agents: **Plan** (DeepSeek + load_skill), **Research** (DeepSeek + web + load_skill), **Build** (DeepSeek + all file tools + skills)

### Provider seam (`codehub/providers/`)
- **Interface**: `function(agent, history, tools)` — runs full agent loop to completion
- **Adapters**: Anthropic (adaptive thinking, tool_use blocks), OpenAI (reasoning_effort, tool_calls blocks), Fake (test harness)
- Both real providers loop: make_request → handle_response → repeat if tool calls present. Retry on transient errors (max 3, exponential backoff).
- Key difference: Anthropic sends system as top-level param; OpenAI sends as message[0]. Anthropic uses `x-api-key` header; OpenAI uses `Authorization: Bearer`.

### Tool seam (`codehub/tools/`)
- **Interface**: Tool = name + description + input schema + callback(history, inputs)
- **File ops**: path sandbox (`is_path_allowed`) restricts to nvim cwd, resolves symlinks to catch traversal
- **Web**: Exa API (`api.exa.ai`) for search + content fetch. Key from .env or `$EXA_API_KEY`
- **Skill loader**: scans `~/.config/nvim/skills/` and `cwd/skills/` for `.md` files with YAML frontmatter

### Async (`core/async.lua`)
- `exec(callback)` — wraps callback in coroutine, provides `await` function
- `await(done_fn)` — yields until `done_fn(done)` calls `done(...)` with results
- Pattern: all HTTP calls go through `await` → `vim.system` with callback → `done()` on completion

### UI
- **Pindow** (`codehub/pindow.lua`): right-pinned vertical split, 3-line input at bottom, output buffer above. ESC closes, Enter submits. Width = max(74, 25% columns).
- **Win** (`codehub/win.lua`): generic floating window factory. Used by Display and CommandWindow.
- **History buffer**: separate `nofile` buffer shared via `agents/history.lua`, rendered into Pindow's output window.

# Coding Conventions

- **OOP via metatables**: `M = {}; M.__index = M; function M.new(...) return setmetatable({...}, M) end`. Methods via `function M:method()` (implicit self).
- **Module pattern**: every file returns a table. Public API via `M.*` or explicit return table. Internal helpers are local functions (prefixed `local function`).
- **Docstrings**: `---` (emacs-style) above functions. Describe **why** not what. `---@param` / `---@return` annotations for LSP.
- **Guard clauses**: nil/type checks at function entry, early return on invalid state.
- **`pcall` for optional loading**: file reads, directory scans wrapped in `pcall` — failures are silent (system stays up).
- **`vim.notify` for errors**: user-facing errors via `vim.notify(msg, "error")`.
- **Keymaps**: `<leader>` as Space, `<localleader>` as `\`. Function-based callbacks preferred over command strings.
- **Buffer/window validity checks**: always call `vim.api.nvim_win_is_valid` / `vim.api.nvim_buf_is_valid` before operating on stale refs.
- **Snacks global**: `Snacks` used bare (not required) — loaded by snacks.nvim plugin globally. Pattern: `Snacks.picker.smart()`, `Snacks.win({...})`, `Snacks.layout.new({...})`.
- **Private members**: leading underscore (`_update_footer`, `_write_message`, `_focused`).
- **String formatting**: `string.format` for numbers, `vim.inspect` for debug dumps.
- **Tool callbacks**: receive `(history, inputs)` — history for debug/error logging, inputs is the parsed args table.

# Beware Of

- **History buffer is shared**: `agents/history.lua` creates one buffer per session. Pindow receives it via constructor. Don't create multiple History instances.
- **Provider closure interface**: providers return a `function(agent, history, tools)` — not an object. The agent loop is fire-and-forget wrapped in `async.exec()`.
- **System prompt in Anthropic is top-level `system` field**, not a message. OpenAI sends it as first message with `role: "system"`. The `get_session_messages` functions differ between providers.
- **OpenAI provider `make_request`** uses `["Authorization"]` vs Anthropic's `["x-api-key"]` header. URL endpoints differ (`/chat/completions` vs `/messages`).
- **Path sandbox**: `is_path_allowed` resolves symlinks via `vim.fn.resolve`. If a symlink points outside cwd, it's rejected. This includes dotfiles that resolve to other paths.
- **`edit_file` count logic**: regex escapes non-word chars with `%` prefix. Gsub-based count may not match exact string if special pattern chars present. Use only for literal string replacement.
- **Retry logic blocks event loop**: `delay_ms` uses `vim.wait` (busy-wait). UI freezes during retries. Acceptable for short delays, but long backoffs will hang nvim.
- **`.env` file**: parsed at `vars.lua` load time. Changes require re-source. Keys are OPENCODE_API_KEY and EXA_API_KEY.
- **OpenCode API**: both Anthropic and OpenAI providers use `opencode.ai` as host (not anthropic.com or openai.com). Models: `minimax-m2.7` (Anthropic path), `deepseek-v4-pro` (OpenAI path).
- **`display.lua` typo**: `add_messsage` (triple-s). Legacy module — not used in current flow. Current flow uses Pindow + history buffer directly.
- **No lazy loading for codehub**: `loader.lua` requires codehub at startup. All agent system prompts, skills, and tools are loaded at nvim init.
- **vim.pack.add**: plugin specs use URL strings, not `owner/repo` format. This is a custom git-clone-based plugin manager, not standard lazy.nvim or packer.

# Key System Goals

- **In-editor AI coding assistant** with tool-use capabilities (file ops, web search, skill loading)
- **Multi-agent architecture**: Plan (read-only), Research (web-enabled), Build (file-editing). Default: Build.
- **Provider portability**: switch between Anthropic-compatible and OpenAI-compatible APIs via config. Currently both routed through OpenCode.
- **Session persistence**: message history, token costs, agent choice tracked in buffer. Session reset via `<leader>cd`.
- **Extensibility**: tools, skills, agents, and providers follow consistent interface patterns. New tool = Tool.new({...}), new provider = closure matching `function(agent, history, tools)`.
- **Safety**: file tools restricted to nvim cwd. API keys in .env (gitignored). Symlink traversal blocked.
- **UI integration**: uses native Neovim windows/splits/floats, not external terminal. Right sidebar for CodeHub, cursor-anchored popups for quick input.
