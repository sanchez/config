---
name: opencode-tools
description: Manage tools in OpenCode - built-in tools, custom tools, and configuration
compatibility: opencode
metadata:
  audience: developers
  workflow: configuration
---

## Overview

Tools allow the LLM to perform actions in your codebase. OpenCode comes with a set of built-in tools, but you can extend it with custom tools or MCP servers.

By default, all tools are **enabled** and don't need permission to run. You can control tool behavior through permissions.

## Configure

Use the `permission` field in opencode.json to control tool behavior:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "deny",
    "bash": "ask",
    "webfetch": "allow"
  }
}
```

You can also use wildcards to control multiple tools at once:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "mymcp_*": "ask"
  }
}
```

## Built-in Tools

### bash

Execute shell commands in your project environment.

```json
{ "permission": { "bash": "allow" } }
```

### edit

Modify existing files using exact string replacements.

```json
{ "permission": { "edit": "allow" } }
```

### write

Create new files or overwrite existing ones. Controlled by the `edit` permission.

```json
{ "permission": { "edit": "allow" } }
```

### read

Read file contents from your codebase.

```json
{ "permission": { "read": "allow" } }
```

### grep

Search file contents using regular expressions.

```json
{ "permission": { "grep": "allow" } }
```

### glob

Find files by pattern matching.

```json
{ "permission": { "glob": "allow" } }
```

### list

List files and directories in a given path.

```json
{ "permission": { "list": "allow" } }
```

### lsp (experimental)

Interact with configured LSP servers for code intelligence (definitions, references, hover, etc.). Only available when `OPENCODE_EXPERIMENTAL_LSP_TOOL=true`.

```json
{ "permission": { "lsp": "allow" } }
```

### patch

Apply patches to files. Controlled by the `edit` permission.

### skill

Load a skill (SKILL.md file) into the conversation.

```json
{ "permission": { "skill": "allow" } }
```

### todowrite

Manage todo lists during coding sessions. Disabled for subagents by default.

```json
{ "permission": { "todowrite": "allow" } }
```

### todoread

Read existing todo lists. Disabled for subagents by default.

```json
{ "permission": { "todoread": "allow" } }
```

### webfetch

Fetch web content from URLs.

```json
{ "permission": { "webfetch": "allow" } }
```

### websearch

Search the web for information. Only available with OpenCode provider or when `OPENCODE_ENABLE_EXA=1`.

```json
{ "permission": { "websearch": "allow" } }
```

### question

Ask the user questions during execution.

```json
{ "permission": { "question": "allow" } }
```

## Custom Tools

Custom tools let you define your own functions that the LLM can call.

### Location

Place tools in:
- `.opencode/tools/` in your project
- `~/.config/opencode/tools/` globally

### Structure

Use the `tool()` helper from `@opencode-ai/plugin`:

```typescript
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Query the project database",
  args: {
    query: tool.schema.string().describe("SQL query to execute"),
  },
  async execute(args) {
    return `Executed query: ${args.query}`
  },
})
```

The filename becomes the tool name.

### Multiple tools per file

Export multiple tools with `<filename>_<exportname>` naming:

```typescript
import { tool } from "@opencode-ai/plugin"

export const add = tool({
  description: "Add two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a + args.b
  },
})

export const multiply = tool({
  description: "Multiply two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a * args.b
  },
})
```

This creates `math_add` and `math_multiply` tools.

### Arguments

Use `tool.schema` (Zod) to define arguments:

```typescript
args: {
  query: tool.schema.string().describe("SQL query to execute")
}
```

Or import Zod directly:

```typescript
import { z } from "zod"

export default {
  description: "Tool description",
  args: {
    param: z.string().describe("Parameter description"),
  },
  async execute(args, context) {
    return "result"
  },
}
```

### Context

Tools receive session context:

```typescript
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Get project information",
  args: {},
  async execute(args, context) {
    const { agent, sessionID, messageID, directory, worktree } = context
    return `Agent: ${agent}, Session: ${sessionID}, Message: ${messageID}, Directory: ${directory}, Worktree: ${worktree}`
  },
})
```

Use `context.directory` for session working directory, `context.worktree` for git worktree root.

### Writing tools in other languages

You can invoke scripts in any language. Example with Python:

Create `.opencode/tools/add.py`:
```python
import sys
a = int(sys.argv[1])
b = int(sys.argv[2])
print(a + b)
```

Create the tool definition `.opencode/tools/python-add.ts`:
```typescript
import { tool } from "@opencode-ai/plugin"
import path from "path"

export default tool({
  description: "Add two numbers using Python",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args, context) {
    const script = path.join(context.worktree, ".opencode/tools/add.py")
    const result = await Bun.$`python3 ${script} ${args.a} ${args.b}`.text()
    return result.trim()
  },
})
```

### Name collisions

Custom tools with the same name as built-in tools take precedence. Use unique names unless intentionally replacing a built-in.

## Ignore patterns

Tools like `grep`, `glob`, and `list` use ripgrep under the hood and respect `.gitignore`. Create a `.ignore` file to include normally ignored paths:

```
!node_modules/
!dist/
!build/
```

## MCP servers

MCP (Model Context Protocol) servers integrate external tools and services. Configure in opencode.json.