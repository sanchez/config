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

-- exit insert mode with double j
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })

-- disable automatic comments when pressing enter on end of line
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')

-- make sure to keep certain number of lines above and below the cursor
vim.opt.scrolloff = 5

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.background = "dark"
vim.opt.termguicolors = true

require("config")
require("loader")

vim.keymap.set('n', '<leader>t', ':terminal<CR>', {})
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {})

-- Move between tabs
vim.keymap.set('n', '<leader>bl', ':bnext<CR>')
vim.keymap.set('n', '<leader>bh', ':bprevious<CR>')
vim.keymap.set("n", "<leader>bd", function()
    local Snacks = require("snacks")
    Snacks.bufdelete.delete()
end)
vim.keymap.set('n', '<leader>bn', function()
    local n = vim.fn.input('Buffer number: ')
    vim.cmd('buffer ' .. n)
end, { desc = "Jump to buffer by number" })

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
