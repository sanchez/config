return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup {}

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        vim.cmd("NvimTreeToggle")
      end,
    })
  end,
}