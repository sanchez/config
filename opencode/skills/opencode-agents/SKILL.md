---
name: opencode-agents
description: Configure and use specialized agents in OpenCode - primary agents, subagents, and custom agents
compatibility: opencode
metadata:
  audience: developers
  workflow: configuration
---

## Overview

Agents are specialized AI assistants configured for specific tasks and workflows. They allow you to create focused tools with custom prompts, models, and tool access.

Use the plan agent to analyze code and review suggestions without making any code changes. Switch between agents during a session or invoke them with the @ mention.

## Types

### Primary agents

Primary agents are the main assistants you interact with directly. You can cycle through them using the Tab key or your configured `switch_agent` keybind. Tool access is configured via permissions.

### Subagents

Subagents are specialized assistants that primary agents can invoke for specific tasks. You can also manually invoke them by @ mentioning them in your messages.

## Built-in agents

### Build (primary)

The default primary agent with all tools enabled. Standard agent for development work.

### Plan (primary)

A restricted agent for planning and analysis. By default, file edits and bash are set to "ask". Useful for analyzing code, suggesting changes, or creating plans without modifying the codebase.

### General (subagent)

A general-purpose agent for researching complex questions and executing multi-step tasks. Has full tool access (except todo).

### Explore (subagent)

A fast, read-only agent for exploring codebases. Cannot modify files. Use for finding files by patterns, searching code for keywords, or answering questions.

### Compaction (primary, hidden)

Hidden system agent that compacts long context into a smaller summary. Runs automatically when needed.

### Title (primary, hidden)

Hidden system agent that generates short session titles. Runs automatically.

### Summary (primary, hidden)

Hidden system agent that creates session summaries. Runs automatically.

## Usage

1. For primary agents, use Tab key to cycle through them during a session.
2. Subagents can be invoked automatically by primary agents or manually by @ mentioning.
3. When subagents create child sessions, use `session_child_first` (default: Leader+Down) to enter the first child.
4. In child sessions: `session_child_cycle` (Right) to cycle next, `session_child_cycle_reverse` (Left) for previous, `session_parent` (Up) to return.

## Configure agents

### JSON

Configure in opencode.json:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "build": {
      "mode": "primary",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "{file:./prompts/build.txt}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    },
    "plan": {
      "mode": "primary",
      "model": "anthropic/claude-haiku-4-20250514",
      "tools": {
        "write": false,
        "edit": false,
        "bash": false
      }
    },
    "code-reviewer": {
      "description": "Reviews code for best practices and potential issues",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```

### Markdown

Define agents using markdown files in:
- Global: ~/.config/opencode/agents/
- Per-project: .opencode/agents/

~/.config/opencode/agents/review.md

```markdown
---
description: Reviews code for quality and best practices
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
---
You are in code review mode. Focus on:
- Code quality and best practices
- Potential bugs and edge cases
- Performance implications
- Security considerations
```

The filename becomes the agent name.

## Options

### Description (required)

Brief description of what the agent does and when to use it.

```json
{ "agent": { "review": { "description": "Reviews code for best practices and potential issues" } } }
```

### Temperature

Control randomness/creativity (0.0-1.0):
- 0.0-0.2: Focused and deterministic (code analysis, planning)
- 0.3-5.0: Balanced (general development)
- 0.6-1.0: Creative (brainstorming)

Default: model-specific (usually 0, 0.55 for Qwen).

### Max steps

Control maximum agentic iterations before forced text response.

```json
{ "agent": { "quick-thinker": { "steps": 5 } } }
```

Use `steps` (not deprecated `maxSteps`).

### Disable

Set to `true` to disable the agent.

```json
{ "agent": { "review": { "disable": true } } }
```

### Prompt

Specify custom system prompt file:

```json
{ "agent": { "review": { "prompt": "{file:./prompts/code-review.txt}" } } }
```

Path is relative to config file location.

### Model

Override the model for this agent:

```json
{ "agent": { "plan": { "model": "anthropic/claude-haiku-4-20250514" } } }
```

Format: `provider/model-id` (e.g., `opencode/gpt-5.1-codex`).

### Tools

Control available tools:

```json
{
  "agent": {
    "plan": {
      "tools": {
        "write": false,
        "bash": false
      }
    }
  }
}
```

Use wildcards for MCP tools:

```json
{ "tools": { "mymcp_*": false } }
```

### Permissions

Configure permissions for edit, bash, and webfetch tools:
- `"ask"`: Prompt for approval
- `"allow"`: Allow all operations
- `"deny"`: Disable the tool

Global:
```json
{ "permission": { "edit": "deny" } }
```

Per-agent override:
```json
{
  "permission": { "edit": "deny" },
  "agent": {
    "build": { "permission": { "edit": "ask" } }
  }
}
```

Specific bash commands:
```json
{
  "agent": {
    "build": {
      "permission": {
        "bash": {
          "git push": "ask",
          "grep *": "allow"
        }
      }
    }
  }
}
```

Glob patterns with wildcards (last matching rule wins):
```json
{
  "permission": {
    "bash": {
      "*": "ask",
      "git status *": "allow"
    }
  }
}
```

### Mode

Set agent mode:
- `primary`: Main conversation agent
- `subagent`: Specialized assistant
- `all`: Default if not specified

```json
{ "agent": { "review": { "mode": "subagent" } } }
```

### Hidden

Hide subagent from @ autocomplete:

```json
{ "agent": { "internal-helper": { "mode": "subagent", "hidden": true } } }
```

Only applies to subagent mode. Can still be invoked via Task tool.

### Task permissions

Control which subagents an agent can invoke via Task tool:

```json
{
  "agent": {
    "orchestrator": {
      "permission": {
        "task": {
          "*": "deny",
          "orchestrator-*": "allow",
          "code-reviewer": "ask"
        }
      }
    }
  }
}
```

Rules evaluated in order, last matching rule wins.

### Color

Customize agent UI color with hex or theme colors: `primary`, `secondary`, `accent`, `success`, `warning`, `error`, `info`.

```json
{ "agent": { "creative": { "color": "#ff6b6b" } } }
```

### Top P

Alternative to temperature for controlling randomness:

```json
{ "agent": { "brainstorm": { "top_p": 0.9 } } }
```

### Additional options

Pass provider-specific options directly:

```json
{
  "agent": {
    "deep-thinker": {
      "model": "openai/gpt-5",
      "reasoningEffort": "high",
      "textVerbosity": "low"
    }
  }
}
```

## Create agents

Use interactive command:

```
opencode agent create
```

This will:
1. Ask where to save (global or project)
2. Get description of agent purpose
3. Generate system prompt and identifier
4. Select tools the agent can access
5. Create markdown file with configuration

## Use cases

- Build agent: Full development with all tools
- Plan agent: Analysis without changes
- Review agent: Code review with read-only access
- Debug agent: Investigation with bash and read
- Docs agent: Documentation with file operations, no system commands

## Examples

### Documentation agent

~/.config/opencode/agents/docs-writer.md

```markdown
---
description: Writes and maintains project documentation
mode: subagent
tools:
  bash: false
---
You are a technical writer. Create clear, comprehensive documentation.
Focus on:
- Clear explanations
- Proper structure
- Code examples
- User-friendly language
```

### Security auditor

~/.config/opencode/agents/security-auditor.md

```markdown
---
description: Performs security audits and identifies vulnerabilities
mode: subagent
tools:
  write: false
  edit: false
---
You are a security expert. Focus on identifying potential security issues.
Look for:
- Input validation vulnerabilities
- Authentication and authorization flaws
- Data exposure risks
- Dependency vulnerabilities
- Configuration security issues
```