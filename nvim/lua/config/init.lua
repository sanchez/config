--- Central configuration. Declares core plugin dependencies, sets up Snacks, binds leader-key maps.
--- All picker keymaps use Snacks.picker (faster than Telescope). LSP pickers bound to g* prefix per convention.
--- Requires sub-config modules (color, editor, git, telescope, which) at end — order ensures overrides apply last.

vim.pack.add({
    -- core libraries
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/folke/snacks.nvim",
    "https://github.com/saghen/blink.lib",
    "https://github.com/j-hui/fidget.nvim",

    -- todo
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/folke/todo-comments.nvim",

    "https://github.com/folke/flash.nvim",
})

require("fidget").setup({})

-- Flash: fast character/treesitter jumping, bound to f/F in normal/visual/operator-pending
require("flash").setup({})
vim.keymap.set({ "n", "x", "o" }, "f", function() require("flash").jump() end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "F", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
vim.keymap.set("c", "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

-- Snacks provides notifier, explorer, dashboard, image viewer, indent guides, input, statuscolumn
local Snacks = require("snacks")
Snacks.setup({
    notifier = { enabled = true },
    explorer = { enabled = true },
    dashboard = {
        enabled = false,
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            -- { section = "startup" },
        },
    },
    image = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    statuscolumn = {
        enabled = true,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = {
            open = false,
            git_hl = false,
        },
        git = {
            patterns = { "GitSign", "MiniDiffSign" },
        },
        refresh = 50,
    },
    picker = {
        sources = {
            explorer = {
                hidden = true,
                ignored = true,
            },
        },
    },
})
require("todo-comments").setup({})

vim.keymap.set("n", "<leader>ft", function()
    Snacks.explorer()
end, { desc = "Toggle File Explorer" })

vim.keymap.set("n", "<leader>gg", function()
    Snacks.lazygit()
end, { desc = "Show LazyGit" })

vim.keymap.set("n", "<leader><space>", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })

-- Iterate keybind table to avoid repetitive vim.keymap.set calls. Each entry: { lhs, rhs, desc }
local keybinds = {
    -- grep
    { "<leader>sb", Snacks.picker.lines, "Buffer Lines" },
    { "<leader>sB", Snacks.picker.grep_buffers, "Grep Open Buffers" },
    { "<leader>sg", Snacks.picker.grep, "Grep" },

    -- search
    { '<leader>s"', Snacks.picker.registers, "Registers" },
    { "<leader>s/", Snacks.picker.search_history, "Search History" },
    { "<leader>sa", Snacks.picker.autocmds, "Autocmds" },
    { "<leader>sb", Snacks.picker.lines, "Buffer Lines" },
    { "<leader>sh", Snacks.picker.command_history, "Command History" },
    { "<leader>sC", Snacks.picker.commands, "Commands" },
    { "<leader>sd", Snacks.picker.diagnostics, "Diagnostics" },
    { "<leader>sD", Snacks.picker.diagnostics_buffer, "Buffer Diagnostics" },
    { "<leader>s?", Snacks.picker.help, "Help Pages" },
    { "<leader>sH", Snacks.picker.highlights, "Highlights" },
    { "<leader>si", Snacks.picker.icons, "Icons" },
    { "<leader>sj", Snacks.picker.jumps, "Jumps" },
    { "<leader>sk", Snacks.picker.keymaps, "Keymaps" },
    { "<leader>sl", Snacks.picker.loclist, "Location List" },
    { "<leader>sm", Snacks.picker.marks, "Marks" },
    { "<leader>sM", Snacks.picker.man, "Man Pages" },
    { "<leader>sp", Snacks.picker.lazy, "Search for Plugin Spec" },
    { "<leader>sq", Snacks.picker.qflist, "Quickfix List" },
    { "<leader>sR", Snacks.picker.resume, "Resume" },
    { "<leader>su", Snacks.picker.undo, "Undo History" },
    { "<leader>sc", Snacks.picker.colorschemes, "Colorschemes" },

    -- LSP
    { "gd", Snacks.picker.lsp_definitions, "Goto Definition" },
    { "gD", Snacks.picker.lsp_declarations, "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references({ jump_single = false }) end, "References" },
    { "gI", Snacks.picker.lsp_implementations, "Goto Implementation" },
    { "gy", Snacks.picker.lsp_type_definitions, "Goto T[y]pe Definition" },
    { "gai", Snacks.picker.lsp_incoming_calls, "C[a]lls Incoming" },
    { "gao", Snacks.picker.lsp_outgoing_calls, "C[a]lls Outgoing" },
    { "<leader>ss", Snacks.picker.lsp_symbols, "LSP Symbols" },
    { "<leader>sS", Snacks.picker.lsp_workspace_symbols, "LSP Workspace Symbols" },

    -- todo comments
    { "<leader>st", function() Snacks.picker.todo_comments() end, "Todo" },
}

for _, x in ipairs(keybinds) do
    vim.keymap.set("n", x[1], function()
        x[2]()
    end, { desc = x[3] })
end


require("config.color")
require("config.editor")
require("config.git")
require("config.telescope")
require("config.which")
