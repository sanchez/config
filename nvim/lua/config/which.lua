--- Which-key: keymap discovery popup. Helix preset for familiar modal-editing layout.
--- <leader>? shows buffer-local keymaps only.

vim.pack.add({
    "https://github.com/folke/which-key.nvim"
})

require("which-key").setup({
    preset = "helix",
})

vim.keymap.set("n", "<leader>?", function()
    require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
