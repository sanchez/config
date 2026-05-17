-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- automatically copy everything to clipboard
vim.opt.clipboard = "unnamedplus"

-- indent spaces set to 4 characters
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- keep the sign column to stop gutter resizing
vim.opt.signcolumn = "yes"

-- disable automatic comments when pressing enter on end of line
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')

-- make sure to keep certain number of lines above and below the cursor
vim.opt.scrolloff = 5

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.background = "dark"
vim.opt.termguicolors = true

require("loader")

require("config.lazy")
vim.cmd("colorscheme catppuccin-latte")

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>ft', function()
    require("snacks").explorer()
end, { desc = "Toggle File Picker" })

vim.keymap.set('n', '<leader>t', ':terminal<CR>', {})
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {})

-- Move between tabs
vim.keymap.set('n', '<leader>bl', ':bnext<CR>')
vim.keymap.set('n', '<leader>bh', ':bprevious<CR>')
vim.keymap.set('n', '<leader>bd', ':bd<CR>')
vim.keymap.set('n', '<leader>bn', function()
    local n = vim.fn.input('Buffer number: ')
    vim.cmd('buffer ' .. n)
end, { desc = "Jump to buffer by number" })

-- Show diagnostics automatically when cursor rests on a line
vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
    end,
})

-- Controls how long before CursorHold fires (in ms), default is 4000
vim.opt.updatetime = 300

-- For some reason I have had issues where the lsp checks didn't run straight away. Copilot came up with this genius plan
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(args)
    local value = vim.tbl_get(args, "data", "params", "value")
    if value and value.kind == "end" and value.title == "Loading workspace" then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "lua_ls" then
        for buf, _ in pairs(client.attached_buffers) do
          client:notify("textDocument/didChange", {
            textDocument = {
              uri = vim.uri_from_bufnr(buf),
              version = vim.lsp.util.buf_versions[buf] or 0,
            },
            contentChanges = {
              { text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") }
            },
          })
        end
      end
    end
  end,
})

-- reload the entire nvim setup
local function reload_config()
    local keys = {}
    for k, _ in pairs(package.loaded) do
        if k:match("^packages") or k:match("^loader") then
            table.insert(keys, k)
            package.loaded[k] = nil
        end
    end
    local keystring = table.concat(keys, ', ')
    print(keystring)

    dofile(vim.env.MYVIMRC)
    -- vim.notify("Config reloaded!", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>r", reload_config, { desc = "Reload config" })
