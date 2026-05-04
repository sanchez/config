return {
  'kdheepak/lazygit.nvim',
  lazy = false,
  dependencies = 'nvim-lua/plenary.nvim',
  config = function()
    vim.g.lazygit_floating_window_scalefactor = 1.0
    vim.g.lazygit_use_custom_config_file_path = 1
    vim.g.lazygit_config_file_path = '/var/home/sanchez/.config/lazygit/config.yml'
  end,
  keys = {
    { '<Leader>gg', '<cmd>LazyGit<cr>', desc = 'Open Lazygit', mode = 'n' },
  },
}