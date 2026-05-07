local M = {}

function M.parse(mapping)
  if type(mapping) == "string" then
    return { lhs = mapping }
  end
  return mapping
end

function M.get_keymap_desc(buf, mode, lhs)
  local maps = vim.api.nvim_buf_get_keymap(buf, mode)
  for _, map in ipairs(maps) do
    if map.lhs == lhs then
      return map.desc or map.rhs
    end
  end
  return nil
end

function M.create_node(name, mapping)
  return {
    name = name,
    mapping = mapping,
    children = {},
    mode = "n",
  }
end

function M.build_tree(mappings, mode)
  local root = M.create_node("root")

  for _, mapping in ipairs(mappings) do
    if mapping.mode and mapping.mode ~= mode then goto continue end

    local lhs = mapping.lhs or mapping[1]
    if not lhs then goto continue end

    local keys = lhs
    if keys:match("^<leader>") then
      keys = keys:gsub("<leader>", "")
    end

    local parts = {}
    for i = 1, #keys do
      table.insert(parts, keys:sub(i, i))
    end

    local current = root
    for _, key in ipairs(parts) do
      if not current.children[key] then
        current.children[key] = M.create_node(key)
      end
      current = current.children[key]
    end

    current.mapping = mapping
    ::continue::
  end

  return root
end

function M.find(root, keys)
  local current = root
  for i = 1, #keys do
    local key = keys:sub(i, i)
    if not current.children[key] then return nil end
    current = current.children[key]
  end
  return current
end

local State = {}

function State.start(opts)
  opts = opts or {}
  return {
    keys = opts.keys or "",
    mode = vim.api.nvim_get_mode().mode,
    started = false,
    timeout = 0,
  }
end

function State.step(state, key)
  if key == vim.NIL or key == "" then
    return { keys = state.keys, changed = false, timeout = true }
  end

  local keys = state.keys .. key
  local key_norm = key:gsub("<Leader>", ""):gsub("<leader>", "")

  if key_norm == "<Esc>" then
    return { keys = "", changed = true, timeout = false, cancelled = true }
  end

  if key_norm == "<BS>" then
    if #state.keys > 0 then
      return { keys = state.keys:sub(1, -2), changed = true, timeout = false }
    end
    return { keys = "", changed = true, timeout = false, cancelled = true }
  end

  return { keys = keys, changed = true, timeout = false }
end

function State.check(state, tree)
  local node = tree
  for i = 1, #state.keys do
    local k = state.keys:sub(i, i)
    if not node.children or not node.children[k] then
      return nil
    end
    node = node.children[k]
  end
  return node
end

function State.is_action(node)
  return node and node.mapping and node.mapping.rhs
end

function State.is_group(node)
  return node and node.children and next(node.children) ~= nil
end

local View = {}

function View.create(opts)
  opts = opts or {}
  local border = opts.border or "single"
  return {
    border = border,
    width = opts.width or 40,
    height = opts.height or 10,
    zindex = opts.zindex or 1000,
  }
end

function View.show(view, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local row = math.floor((vim.o.lines - view.height) / 2)
  local col = math.floor((vim.o.columns - view.width) / 2)

  local win_opts = {
    relative = "editor",
    width = view.width,
    height = view.height,
    row = row,
    col = col,
    style = "minimal",
    border = view.border,
    noautocmd = true,
    zindex = view.zindex,
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.api.nvim_win_set_option(win, "foldenable", false)
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "scrollbind", false)

  return win, buf
end

function View.format_node(key, node, opts)
  opts = opts or {}
  local key_width = opts.key_width or 15

  local desc = ""
  if node.mapping then
    desc = node.mapping.desc or node.mapping[2] or ""
  end

  if type(desc) == "function" then
    desc = "[function]"
  elseif type(desc) ~= "string" then
    desc = tostring(desc)
  end

  local padding = key_width - #key
  local key_str = key .. string.rep(" ", padding)

  return key_str .. desc
end

function View.format_tree(root, keys, opts)
  opts = opts or {}
  local lines = {}
  local highlights = {}
  local max_width = opts.width or 40

  local node = root
  for i = 1, #keys do
    node = node.children and node.children[keys:sub(i, i)]
    if not node then break end
  end

  if not node or not node.children then
    return {}, {}
  end

  local sorted = {}
  for k, _ in pairs(node.children) do
    table.insert(sorted, k)
  end
  table.sort(sorted)

  local line_num = 0
  for _, key in ipairs(sorted) do
    local child = node.children[key]
    local prefix = child.children and "" or "  "
    local line = View.format_node(prefix .. key, child, opts)
    lines[line_num + 1] = line
    line_num = line_num + 1
  end

  return lines, highlights
end

function View.hide(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

local wk = {
  opts = {
    triggers = { "<auto>" },
    preset = "classic",
    delay = 200,
    sort = { "alphanum", "order" },
    layout = { height = { min = 4, max = 12 }, width = { min = 20, max = 50 } },
    win = {
      border = "single",
      zindex = 1000,
    },
  },
  state = {
    active = false,
    keys = "",
    mode = "n",
    win = nil,
    buf = nil,
  },
  registered_mappings = {},
  trees = {},
}

function M.setup(opts)
  wk.opts = vim.tbl_deep_extend("force", wk.opts, opts or {})
  wk.state.win = nil
  wk.state.buf = nil
end

function M.register(mappings_opts)
  if not mappings_opts then return end

  local spec = mappings_opts.spec or mappings_opts
  local mode = mappings_opts.mode or "n"
  local buffer = mappings_opts.buffer or 0

  local tree = M.build_tree(spec, mode)
  wk.trees[buffer] = wk.trees[buffer] or {}
  wk.trees[buffer][mode] = tree

  for _, spec_item in ipairs(spec) do
    local lhs = spec_item[1] or spec_item.lhs
    if lhs and spec_item[2] then
      local mapping = {
        lhs = lhs,
        rhs = spec_item[2],
        desc = spec_item.desc or "",
        mode = mode,
        buffer = buffer,
      }
      table.insert(wk.registered_mappings, mapping)
    end
  end

  for lhs, rhs in pairs(spec) do
    if type(lhs) == "string" and lhs:match("^<leader>") then
      local key = lhs:gsub("<leader>", "")
      local desc = ""
      local fn = nil

      if type(rhs) == "table" then
        desc = rhs.desc or ""
        fn = rhs[1]
      else
        fn = rhs
      end

      table.insert(wk.registered_mappings, {
        lhs = lhs,
        rhs = fn,
        desc = desc,
        mode = mode,
        buffer = buffer,
      })
    end
  end
end

function M.show(opts)
  opts = opts or {}
  local global = opts.global ~= false

  local mode = vim.api.nvim_get_mode().mode
  local buffer = global and 0 or vim.api.nvim_get_current_buf()

  local tree = nil
  if wk.trees[buffer] and wk.trees[buffer][mode] then
    tree = wk.trees[buffer][mode]
  elseif wk.trees[0] and wk.trees[0][mode] then
    tree = wk.trees[0][mode]
  end

  if not tree then
    tree = M.build_tree(wk.registered_mappings, mode)
  end

  local state_obj = State.start({ keys = "" })
  wk.state.active = true
  wk.state.keys = ""

  local view_opts = {
    width = wk.opts.layout.width.max,
    border = wk.opts.win.border,
    key_width = 15,
  }

  while true do
    local lines, _ = View.format_tree(tree, wk.state.keys, view_opts)
    if #lines == 0 then
      lines = { "  (no mappings)" }
    end

    local height = math.min(#lines + 2, wk.opts.layout.height.max or 12)
    local width = math.min(view_opts.width, wk.opts.layout.width.max or 50)

    view_opts.height = height

    if wk.state.win and vim.api.nvim_win_is_valid(wk.state.win) then
      vim.api.nvim_win_close(wk.state.win, true)
    end

    local all_lines = {}
    if #wk.state.keys > 0 then
      table.insert(all_lines, "  " .. wk.state.keys .. ":")
      table.insert(all_lines, "")
    end
    for i, line in ipairs(lines) do
      all_lines[i + (#wk.state.keys > 0 and 2 or 0)] = line
    end

    local full_height = #all_lines + 2
    view_opts.height = math.min(full_height, wk.opts.layout.height.max or 12)
    view_opts.width = math.min(width, wk.opts.layout.width.max or 50)

    wk.state.win, wk.state.buf = View.show(view_opts, all_lines)

    vim.cmd([[highlight WhichKeyNormal gui=italic guifg=#c6c6c6 cterm=italic ctermfg=188]])

    local key = vim.fn.getcharstr()
    local result = State.step(state_obj, key)

    if result.cancelled or result.timeout then
      break
    end

    if not result.changed then
      goto continue
    end

    if result.keys == "" then
      break
    end

    wk.state.keys = result.keys

    local node = State.check(state_obj, tree)
    if not node then
      break
    end

    if State.is_action(node) then
      vim.api.nvim_win_close(wk.state.win, true)
      wk.state.win = nil
      wk.state.active = false

      local rhs = node.mapping.rhs
      if type(rhs) == "function" then
        rhs()
      else
        vim.cmd(rhs)
      end
      return
    end

    if not State.is_group(node) then
      break
    end

    ::continue::
  end

  if wk.state.win and vim.api.nvim_win_is_valid(wk.state.win) then
    vim.api.nvim_win_close(wk.state.win, true)
  end
  wk.state.win = nil
  wk.state.active = false
end

function M.trigger(prefix)
  prefix = prefix or "<leader>"
  wk.state.keys = prefix
  M.show({ global = false })
end

vim.api.nvim_create_user_command("WhichKey", function(opts)
  M.show({ global = opts.args ~= "local" })
end, {
  nargs = "?",
  complete = function()
    return { "local", "global" }
  end,
})

return M
