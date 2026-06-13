# dotfiles

Personal configuration for my Bazzite setup.

## Structure

```
~/.config/
├── nvim/            Neovim + CodeHub AI assistant
├── opencode/        (Legacy) OpenCode AI coding agent
├── ghostty/         Ghostty terminal emulator
├── lazygit/         Git TUI
└── .gitignore       Excludes KDE auto-generated files
```

## [nvim](./nvim/)

Neovim IDE with **CodeHub** — an embedded AI coding assistant. Chat with LLMs directly in-editor. Agents can read, write, edit, search, and execute tools on your codebase. All file access is cwd-bounded for security.

**Key features:**
- AI chat via `<leader>cc` (Pindow popup)
- Extensible agent/tool/provider/skill system loaded from directories
- Project overrides via `.hub/` — drop agents, tools, skills alongside your code
- LSP with blink.cmp, Flash jump, Snacks picker ecosystem
- Catppuccin Frappe theme, 4-space indent, `jj` escape

See [nvim/README.md](./nvim/README.md) for full architecture and keymaps.

## [ghostty](./ghostty/)

Terminal emulator config. Catppuccin Frappe theme, Cascadia Code font, custom cursor shaders.

- **Shaders:** cursor_sweep, cursor_tail, cursor_warp, sonic_boom_cursor, ripple_cursor, rectangle_boom_cursor, ripple_rectangle_cursor
- Window padding balance enabled

## Setup

```bash
git clone <repo-url> ~/.config
```
