# CodeHub — AI-native Neovim

CodeHub is an AI-assisted coding environment embedded in Neovim. Chat with LLM agents directly inside your editor — they read files, edit code, run searches, and execute tools on your behalf. All file access is security-bounded to the current working directory.

## Architecture

```
~/.config/nvim/
├── init.lua                    Entry point
├── lua/
│   ├── config/                 Editor config (LSP, colorscheme, keybinds)
│   │   ├── init.lua            Plugin bootstrap + leader keymaps
│   │   ├── color.lua           Catppuccin Frappe theme
│   │   ├── editor.lua          LSP, blink.cmp, lualine, bufferline
│   │   └── git.lua             Gitsigns
│   ├── packages/codehub/       AI framework (self-contained)
│   │   ├── init.lua            Keymaps + wiring
│   │   ├── agents.lua          Agent registry (load + filter tools/skills)
│   │   ├── tools.lua           Tool registry + cwd security boundary
│   │   ├── skills.lua          Skill registry (markdown docs as context)
│   │   ├── providers.lua       Provider registry + HUB global injection
│   │   ├── config_loader.lua   Generic .lua/.md file loader (YAML frontmatter)
│   │   ├── history.lua         Session history + buffer rendering
│   │   ├── pindow.lua          Chat popup window (input + output panes)
│   │   ├── net.lua             HTTP via curl subprocess (no plenary dep)
│   │   ├── async.lua           Coroutine-based async helper
│   │   ├── win.lua             Floating window factory
│   │   ├── commandwindow.lua   Cursor-anchored command overlay
│   │   └── message.lua         Collapsible message tree node
│   └── loader.lua              Bootstrap: require("packages.codehub")
├── agents/                     Agent definitions (.lua or .md)
│   ├── Build.lua               General-purpose coding agent
│   └── Build.md                Build agent system prompt
├── providers/                  Provider backends
│   ├── openai.lua              OpenAI-compatible via opencode.ai
│   └── anthropic.lua           Anthropic (planned)
├── tools/                      LLM-callable tools
│   ├── file_read.lua
│   ├── file_write.lua
│   ├── file_edit.lua
│   ├── file_delete.lua
│   ├── file_list.lua
│   ├── glob.lua
│   ├── search_text.lua         Ripgrep wrapper
│   ├── get_document_symbols.lua Treesitter symbols
│   └── search_symbols.lua      LSP workspace symbols
├── skills/                     Markdown docs loaded as system context
│   ├── agents-md.md
│   ├── create-skill.md
│   └── nvim_lua.md
├── AGENTS.md                   Project coding conventions (read by agents)
└── .env                        API keys (gitignored)
```

## Keymaps

| Binding | Action |
|---|---|
| `<leader>cc` | Open CodeHub chat (Pindow) |
| `<leader>ca` | Select AI agent |
| `<leader>cd` | Reset chat session |
| `<leader>r` | Reload config (live-reload CodeHub modules) |
| `<leader>sg` | Grep project |
| `<leader>sb` | Search buffer lines |
| `gd` / `gr` | LSP definition / references |
| `f` / `F` | Flash character / treesitter jump |

## Agents

Agents are defined in `agents/` as `.lua` files returning a config table or `.md` files with YAML frontmatter + system prompt body. Each agent specifies:

- `description` — displayed in agent picker
- `provider` — backend name (matches a file in `providers/`)
- `model` — LLM model identifier
- `tools.allowed` / `tools.denied` — tool access control
- `skills.allowed` / `skills.denied` — skill access control

### Built-in agents

| Agent | Role |
|---|---|
| **Build** | General coding — reads, writes, edits, searches. Deepseek-v4-pro. |

Project-specific agents go in `.hub/agents/` alongside per-project tools, providers, and skills.

## Tools

Tools are `.lua` files returning `{description, inputs, callback}`. The callback receives user-provided arguments and a `history` handle for debug logging. All file-operation tools enforce a **cwd security boundary** — paths must resolve within the current working directory. Path traversal attempts are blocked.

Inputs with `_` prefix are hidden from the LLM's required-parameter schema (private params passed out-of-band by the system).

## Skills

Skills are `.md` files with YAML frontmatter describing what they cover. The content body is injected into the system prompt when the LLM calls `load_skill`. This keeps the base system prompt lean while giving the model access to detailed documentation on demand.

## Providers

Providers implement `callback(agent, history, done)`. OpenAI provider handles:
- System message construction (agent.content + skills + AGENTS.md)
- Tool call mapping (OpenAI function-calling format)
- Reasoning content logging (deepseek thinking)
- Retry logic (1 retry on failure)
- Recursive tool call loops (model calls tools → results fed back → model responds)

## Project overrides (`.hub/`)

Any directory can contain a `.hub/` folder with:
- `.hub/agents/` — additional or override agents
- `.hub/tools/` — additional or override tools
- `.hub/skills/` — additional or override skills
- `.hub/providers/` — additional or override providers

An `AGENTS.md` file at the project root is automatically injected as a system message — use it for project-specific coding conventions.

## Setup

```bash
# Clone into Neovim config directory
git clone <repo-url> ~/.config/nvim

# Set API key
echo 'OPENCODE_API_KEY="your-key"' > ~/.config/nvim/.env

# Launch Neovim — plugins install automatically on first start
nvim
```

## Security

- File read/write/edit/delete tools validate all paths against `vim.fn.getcwd()`
- Symlink resolution via `vim.fn.resolve` prevents bypasses
- Path traversal (`../`) blocked
- `.git` directories excluded from file listing
- `.env` is gitignored — API keys never committed

## Design Principles

- **AI-native, not bolted-on.** Agent interaction is the primary interface — `<leader>cc` opens chat from any buffer.
- **Extensible by convention.** Directory loading means adding a file = adding capability. No central registry edits.
- **Safety by default.** LLM can only touch files in the project it's helping with.
- **Minimal dependencies.** No plenary, no socket lib. HTTP via curl. Async via coroutines.
- **Locality.** Project-specific overrides live in `.hub/` alongside the code they assist.
- **Single-machine, single-user.** No cross-platform abstractions. 4-space indent. Catppuccin Frappe.
