---
name: opencode-commands
description: Create custom commands for repetitive tasks in OpenCode
compatibility: opencode
metadata:
  audience: developers
  workflow: configuration
---

## Overview

Custom commands let you specify a prompt to run when that command is executed in the TUI.

```
/my-command
```

Custom commands are in addition to built-in commands like `/init`, `/undo`, `/redo`, `/share`, `/help`.

## Create command files

Create markdown files in the `commands/` directory to define custom commands.

.opencode/commands/test.md

```markdown
---
description: Run tests with coverage
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---
Run the full test suite with coverage report and show any failures.
Focus on the failing tests and suggest fixes.
```

Use the command by typing `/` followed by the command name:

```
"/test"
```

## Configure

### JSON

Use the `command` option in opencode.json:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "command": {
    "test": {
      "template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes.",
      "description": "Run tests with coverage",
      "agent": "build",
      "model": "anthropic/claude-3-5-sonnet-20241022"
    }
  }
}
```

Run in TUI:

```
/test
```

### Markdown

Define commands using markdown files in:
- Global: ~/.config/opencode/commands/
- Per-project: .opencode/commands/

~/.config/opencode/commands/test.md

```markdown
---
description: Run tests with coverage
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---
Run the full test suite with coverage report and show any failures.
Focus on the failing tests and suggest fixes.
```

The filename becomes the command name.

## Prompt config

### Arguments

Pass arguments using `$ARGUMENTS` placeholder:

.opencode/commands/component.md

```markdown
---
description: Create a new component
---
Create a new React component named $ARGUMENTS with TypeScript support.
Include proper typing and basic structure.
```

Run with arguments:

```
/component Button
```

Use positional parameters:
- $1 - First argument
- $2 - Second argument
- $3 - Third argument

.opencode/commands/create-file.md

```markdown
---
description: Create a new file with content
---
Create a file named $1 in the directory $2
with the following content: $3
```

Run:

```
/create-file config.json src "{ \"key\": \"value\" }"
```

### Shell output

Use *!`command`* to inject bash command output into your prompt.

To analyze test coverage:

.opencode/commands/analyze-coverage.md

```markdown
---
description: Analyze test coverage
---
Here are the current test results:
!`npm test`
Based on these results, suggest improvements to increase coverage.
```

To review recent changes:

.opencode/commands/review-changes.md

```markdown
---
description: Review recent changes
---
Recent git commits:
!`git log --oneline -10`
Review these changes and suggest any improvements.
```

Commands run in the project's root directory.

### File references

Include files using `@` followed by the filename:

.opencode/commands/review-component.md

```markdown
---
description: Review component
---
Review the component in @src/components/Button.tsx.
Check for performance issues and suggest improvements.
```

## Options

### Template (required)

The prompt sent to the LLM when command is executed:

```json
{
  "command": {
    "test": {
      "template": "Run the full test suite with coverage report..."
    }
  }
}
```

### Description

Brief description shown in the TUI:

```json
{
  "command": {
    "test": {
      "description": "Run tests with coverage"
    }
  }
}
```

### Agent

Specify which agent executes the command. If a subagent, triggers subagent invocation by default. Set `subtask: false` to disable:

```json
{
  "command": {
    "review": {
      "agent": "plan"
    }
  }
}
```

Defaults to current agent if not specified.

### Subtask

Force subagent invocation. Useful to avoid polluting primary context, even if agent mode is `primary`:

```json
{
  "command": {
    "analyze": {
      "subtask": true
    }
  }
}
```

### Model

Override the default model for this command:

```json
{
  "command": {
    "analyze": {
      "model": "anthropic/claude-3-5-sonnet-20241022"
    }
  }
}
```

## Built-in

OpenCode includes built-in commands: `/init`, `/undo`, `/redo`, `/share`, `/help`.

Custom commands can override built-in commands if they have the same name.