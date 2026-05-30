---
description: "Documentation for how to code Lua inside nvim"
---

# Neovim Lua Guide

Source: [Neovim Lua Documentation](https://neovim.io/doc/user/lua/)

## Table of Contents

1. [Introduction](#introduction)
2. [Lua Concepts and Idioms](#lua-concepts-and-idioms)
3. [Importing Lua Modules](#importing-lua-modules)
4. [Commands](#commands)
5. [luaeval()](#luaeval)
6. [Vimscript v:lua Interface](#v:lua-interface)
7. [Lua Standard Library](#lua-standard-library)
8. [Lua-Vimscript Bridge](#lua-vimscript-bridge)

---

## Introduction

Neovim includes a built-in Lua 5.1 script engine. The Lua engine complements:
- **vimscript functions** + **Ex commands**
- **API** functions

These three namespaces form the Nvim programming interface.

### Lua Compatibility

- Lua 5.1 is the permanent interface for Nvim Lua
- LuaJIT is recommended for performance on supported platforms
- The `jit` global variable can be used to detect LuaJIT:

```lua
if jit then
  -- LuaJIT code
else
  -- Plain Lua 5.1 code
end
```

### Profiling

When built with LuaJIT, Lua code can be profiled:

```lua
require('jit.p').start('ri1', '/tmp/profile')
-- ... perform tasks ...
require('jit.p').stop()
```

---

## Lua Concepts and Idioms

### Tables

Tables are the primary data structure in Lua, representing both lists (arrays) and dictionaries (maps).

### Closures

Every scope in Lua is a closure:
- A function is a closure
- A module is a closure
- A `do` block is a closure

### Coroutines

Stackful coroutines enable cooperative multithreading, generators, and versatile control flow.

### Error Handling

Lua functions may throw errors for exceptional failures. Handle with `pcall()`:

```lua
local success, result = pcall(fn)
```

### Result-or-Message Pattern

When failure is expected, return `nil` to signal failure. This "result-or-message" pattern uses multi-value returns:

```lua
---@return any|nil    -- result on success, nil on failure
---@return nil|string -- nil on success, error message on failure
```

### Iterators and Iterables

An **iterator** is a function that can be called repeatedly to get the "next" value of a collection.

An **iterable** is anything that `vim.iter()` can consume: tables, dicts, lists, iterator functions, tables implementing `__call()` metamethod, and `vim.iter()` objects.

### Function Calls

Lua functions can be called with positional arguments. Missing arguments are `nil`, extra parameters are silently discarded.

### kwargs (Keyword Arguments)

When calling a function, parentheses can be omitted if the function takes exactly one string literal or table literal:

```lua
func_with_opts { foo = true, filename = "hello.world" }
```

### Patterns (not Regex)

Lua uses limited patterns instead of regex:

```lua
string.match("foo123bar", "%d+")        -- "123"
string.match("foo123bar", "[^%d]+")    -- "foo"
```

### Truthy Values

Only `false` and `nil` evaluate to "false". All other values are "true".

---

## Importing Lua Modules

Modules are searched under directories specified in `runtimepath`.

For a module `foo.bar`, each directory is searched for:
1. `lua/foo/bar.lua`
2. `lua/foo/bar/init.lua`
3. `lua/foo/bar.so` (or `.dll`)

The return value is cached after the first `require()` call.

### Getting Script Location

```lua
debug.getinfo(1, 'S').source:gsub('^@', '')
```

---

## Commands

### :lua

Executes a Lua chunk:

```vim
:lua vim.api.nvim_command('echo "Hello, Nvim!"')
:lua =jit.version  -- print LuaJIT version
```

### :luafile

Execute a Lua script from a file:

```vim
:luafile script.lua
:luafile %
```

### :luado

Executes Lua chunk for each buffer line:

```vim
:luado return string.format("%s\t%d", line:reverse(), #line)
```

### :lua-heredoc

Execute Lua script from within Vimscript:

```vim
function! CurrentLineInfo()
lua << EOF
local linenr = vim.api.nvim_win_get_cursor(0)[1]
print(string.format('Line %d', linenr))
EOF
endfunction
```

---

## luaeval()

Pass Lua values to Nvim using `luaeval()`. It takes an expression string and optional argument:

```vim
:echo luaeval('_A[1] + _A[2]', [40, 2])  " 42
:echo luaeval('string.match(_A, "[a-z]+")', 'XYXfoo123')  " foo
```

### Table Ambiguity

Lua tables can be lists or dicts:
- **List**: Empty table or table with N consecutive integer keys 1…N
- **Dict**: Table with string keys

Use `vim.empty_dict()` for empty dictionary, `vim.type_idx`/`vim.types` for special table types.

---

## v:lua Interface

Call Lua functions from Vimscript:

```vim
call v:lua.func(arg1, arg2)
call v:lua.require'mypack'.func(arg1, arg2)
```

**Note**: Only single quote form without parentheses works.

Can be used in "func" options like `'omnifunc'`:

```lua
vim.bo[buf].omnifunc = 'v:lua.mymod.omnifunc'
```

---

## Lua Standard Library

The Nvim Lua standard library is the `vim` module, always loaded.

### vim.uv (libUV)

`vim.uv` exposes libUV bindings for networking, filesystem, and process management.

**Important**: Cannot directly invoke `vim.api` functions in `vim.uv` callbacks. Use `vim.schedule_wrap()`:

```lua
timer:start(1000, 0, vim.schedule_wrap(function()
  vim.api.nvim_command('echomsg "test"')
end))
```

**Examples**:

```lua
-- Repeating timer
local timer = vim.uv.new_timer()
timer:start(1000, 750, function()
  print('timer invoked!')
  if i > 4 then timer:close() end
  i = i + 1
end)

-- File-change detection
local w = vim.uv.new_fs_event()
w:start(fullpath, {}, vim.schedule_wrap(function(...) on_change(...) end))

-- TCP echo-server
local server = vim.uv.new_tcp()
server:bind('0.0.0.0', 0)
server:listen(128, function(err) ... end)
```

### vim.builtin

- `vim.api` - Invokes Nvim API functions
- `vim.NIL` - Special value representing NIL in RPC
- `vim.type_idx` / `vim.val_idx` - Type indices for special tables
- `vim.types` - Table with values for type indices (`float`, `array`, `dictionary`)
- `vim.log.levels` - DEBUG, ERROR, INFO, TRACE, WARN, OFF

### vim Functions

- `vim.empty_dict()` - Creates empty dictionary
- `vim.iconv(str, from, to)` - Character encoding conversion
- `vim.in_fast_event()` - Returns true if in fast event handler
- `vim.rpcnotify(channel, method, ...)` - Send RPC event
- `vim.rpcrequest(channel, method, ...)` - Invoke RPC method
- `vim.schedule(fn)` - Schedule function in main event loop
- `vim.str_utf_end(str, index)` - Get UTF codepoint end distance
- `vim.str_utf_pos(str)` - Get UTF codepoint start positions
- `vim.str_utf_start(str, index)` - Get UTF codepoint start distance
- `vim.stricmp(a, b)` - Case-insensitive string comparison
- `vim.ui_attach(ns, opts, callback)` - Subscribe to UI events (experimental)
- `vim.ui_detach(ns)` - Detach UI callback

---

## Lua-Vimscript Bridge

Nvim Lua provides interface to Vimscript variables, functions, and options.

**Note**: Objects passed over the bridge are COPIED (marshalled), not referenced.

### vim.call()

Invokes Vim function:

```lua
vim.call('func', arg1, arg2)  -- or vim.fn['func'](arg1, arg2)
```

### vim.cmd()

Executes Vimscript commands:

```lua
vim.cmd('echo 42')
vim.cmd([[
  augroup my.group
    autocmd!
  augroup END
]])
vim.cmd.edit({ '%foo"|bar#baz"', magic = { file = false, bar = false } })
```

### vim.fn

Invokes Vim function or user function:

```lua
vim.fn['some#function']({...})
```

### Vim Variables

Access Vim editor variables:
- `vim.g` - Global (g:) variables
- `vim.b` - Buffer-scoped (b:) variables
- `vim.w` - Window-scoped (w:) variables
- `vim.t` - Tabpage-scoped (t:) variables
- `vim.v` - v: variables

```lua
vim.g.foo = 5
print(vim.g.foo)
vim.g.foo = nil  -- Delete variable
```

**Important**: Setting dictionary fields directly won't persist. Must write whole dictionary:

```lua
local my_dict = vim.g.my_dict
my_dict.field1 = 'value'
vim.g.my_dict = my_dict
```

### Vim Options

- `vim.o` - Options (like `:set`)
- `vim.bo[bufnr]` - Buffer-scoped options
- `vim.wo[winid]` - Window-scoped options
- `vim.go` - Global options (like `:setglobal`)
- `vim.env` - Environment variables

```lua
vim.o.number = true
vim.o.wildignore = '*.o,*.a,__pycache__'
vim.bo.bufnr.buflisted = true
vim.env.FOO = 'bar'
```

### vim.opt

A special interface for list/map options with object-oriented methods:

```lua
vim.opt.wildignore = { '*.o', '*.a', '__pycache__' }
vim.opt.wildignore:append { "*.pyc" }
vim.opt.wildignore:prepend { "new_first" }
vim.opt.wildignore:remove { "node_modules" }
vim.opt:get()  -- Get option value
```

Also available: `vim.opt_local` and `vim.opt_global`.

---

## Additional vim Module Functions

- `vim.defer_fn(fn, timeout)` - One-shot timer
- `vim.deprecate(name, alternative, version, plugin)` - Show deprecation message
- `vim.inspect(x, opts?)` - Human-readable representation
- `vim.keycode(str)` - Translates keycodes
- `vim.notify(msg, level, opts)` - Display notification
- `vim.notify_once(msg, level, opts)` - Display notification once
- `vim.on_key(fn, ns_id, opts)` - Listen to every input key
- `vim.paste(lines, phase)` - Paste handler hook
- `vim.print(...)` - Pretty print
- `vim.schedule_wrap(fn)` - Wrap function for scheduling
- `vim.wait(time, callback, interval, fast_only)` - Wait with event processing

---

## vim.inspector Module

- `vim.inspect_pos(buf, row, col, filter)` - Get all items at buffer position
- `vim.show_pos(buf, row, col, filter)` - Show items at buffer position

---

## vim Ringbuf

`vim.ringbuf(size)` - Create ring buffer with methods:
- `push(item)` - Add item (overwrites oldest if full)
- `pop()` - Remove and return first item
- `peek()` - Return first item without removing
- `clear()` - Clear all items

---

## Table Utility Functions (vim.*)

### List Functions
- `vim.list.bisect(t, val, opts)` - Search sorted list position
- `vim.list.unique(t, key?)` - Remove duplicates in-place
- `vim.list_contains(t, value)` - Check if list contains value
- `vim.list_extend(dst, src, start, finish)` - Extend list
- `vim.list_slice(list, start, finish)` - Create slice

### Table Functions
- `vim.deep_equal(a, b)` - Deep comparison
- `vim.deepcopy(orig, noref?)` - Deep copy
- `vim.defaulttable(createfn)` - Table with default values
- `vim.tbl_contains(t, value, opts?)` - Check if table contains value
- `vim.tbl_count(t)` - Count non-nil values
- `vim.tbl_deep_extend(behavior, ...)` - Merge tables recursively
- `vim.tbl_extend(behavior, ...)` - Merge tables
- `vim.tbl_filter(fn, t)` - Filter table
- `vim.tbl_get(o, ...)` - Get nested value
- `vim.tbl_isempty(t)` - Check if empty
- `vim.tbl_keys(t)` - Get all keys
- `vim.tbl_map(fn, t)` - Map function over values
- `vim.tbl_values(t)` - Get all values
- `vim.is_callable(f)` - Check if callable
- `vim.isarray(t)` - Check if array
- `vim.islist(t)` - Check if list (contiguous integers from 1)
- `vim.isnil(t)` - Check if nil or vim.NIL

### String Functions
- `vim.endswith(s, suffix)` - Test string ending
- `vim.startswith(s, prefix)` - Test string beginning
- `vim.split(s, sep, opts?)` - Split string
- `vim.gsplit(s, sep, opts?)` - Lazy string split iterator
- `vim.trim(s)` - Trim whitespace
- `vim.pesc(s)` - Escape magic pattern chars

### Other Functions
- `vim.nonnil(...)` - Return first non-nil argument
- `vim.npcall(fn, ...)` - Protected call (returns nil on error)
- `vim.validate(name, value, validator, optional, message)` - Validate arguments
- `vim.spairs(t)` - Sorted pairs iteration

---

## vim.base64 Module

- `vim.base64.decode(str)` - Decode Base64 string
- `vim.base64.encode(str)` - Encode to Base64

---

## vim.filetype Module

- `vim.filetype.add(filetypes)` - Add new filetype mappings
- `vim.filetype.get_option(filetype, option)` - Get default filetype option
- `vim.filetype.inspect()` - Inspect filetype registry
- `vim.filetype.match(args)` - Perform filetype detection

---

## vim.fs Module (Filesystem)

- `vim.fs.abspath(path)` - Convert to absolute path
- `vim.fs.basename(file)` - Get basename
- `vim.fs.dirname(file)` - Get parent directory
- `vim.fs.ext(file)` - Get file extension
- `vim.fs.find(names, opts?)` - Find files/directories
- `vim.fs.joinpath(...)` - Concatenate paths
- `vim.fs.normalize(path, opts?)` - Normalize path
- `vim.fs.parents(start)` - Iterate parent directories
- `vim.fs.relpath(base, target)` - Get relative path
- `vim.fs.rm(path, opts?)` - Remove file/directory
- `vim.fs.root(source, marker)` - Find root directory with marker

---

## vim.iter

`vim.iter()` creates an iterator object with chainable methods:

```lua
vim.iter({1, 2, 3, 4, 5}):filter(function(x) return x % 2 == 0 end):map(function(x) return x * 2 end):totable()
```

---

## API Extensions

- `vim.pretty_print(...)` - Formatted print
- `vim.ui.open()` - Open file/URL with system handler
- `vim.cmd` - Command execution interface

---

For more details, see the full [Neovim Lua documentation](https://neovim.io/doc/user/lua/).
