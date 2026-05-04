return {
  'kdheepak/lazygit.nvim',
  lazy = false,
  dependencies = 'nvim-lua/plenary.nvim',
  config = function()
    vim.g.lazygit_floating_window_scalefactor = 1.0
  end,
  keys = {
    { '<Leader>gg', '<cmd>LazyGit<cr>', desc = 'Open Lazygit', mode = 'n' },
  },
}