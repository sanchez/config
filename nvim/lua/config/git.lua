vim.pack.add({
    "https://github.com/kdheepak/lazygit.nvim",
})

vim.g.lazygit_floating_window_scalefactor = 1.0
vim.g.lazygit_use_custom_config_file_path = 1
vim.g.lazygit_config_file_path = vim.fn.expand("~/.config/lazygit/config.yml")

-- vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "Open Lazygit" })
