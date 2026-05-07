-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.background = "dark"
vim.opt.termguicolors = true

require("config.lazy")

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>ft', function() require("nvim-tree.api").tree.toggle() end, { desc = "Toggle nvim-tree" })

vim.keymap.set('n', '<leader>t', ':terminal<CR>', {})
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {})

local wk = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "packages", "which-key-local", "init.lua"))
wk.setup()
vim.keymap.set("n", "<leader>?", function() wk.show({ global = false }) end, { desc = "Buffer Local Keymaps" })
