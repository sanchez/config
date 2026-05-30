return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  -- dependencies = {
  --   "nvim-tree/nvim-web-devicons",
  -- },
  config = function()
    require("nvim-tree").setup({})
    -- web_devicons.file.enable = false
  --
  --   vim.api.nvim_create_autocmd("User", {
  --     pattern = "LazyDone",
  --     callback = function()
  --       local api = require("nvim-tree.api")
  --       api.tree.open({ focus = false })
  --       vim.defer_fn(function()
  --         local wins = vim.api.nvim_list_wins()
  --         for _, w in ipairs(wins) do
  --           local buf = vim.api.nvim_win_get_buf(w)
  --           if vim.bo[buf].filetype ~= "NvimTree" and vim.api.nvim_win_is_valid(w) then
  --             vim.api.nvim_set_current_win(w)
  --             return
  --           end
  --         end
  --       end, 50)
  --     end,
  --   })
  --
  --   vim.api.nvim_create_autocmd("QuitPre", {
  --     callback = function()
  --       for _, win in ipairs(vim.api.nvim_list_wins()) do
  --         if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree" then
  --           vim.api.nvim_win_close(win, true)
  --         end
  --       end
  --     end,
  --   })
  end,
}
