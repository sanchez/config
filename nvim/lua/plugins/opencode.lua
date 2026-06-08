--- Opencode.nvim plugin spec. AI coding assistant overlay. Dependencies: plenary, blink.lib, render-markdown, blink.cmp, snacks.
--- Renders output as markdown in opencode_output filetype. Anti-conceal disabled so code blocks remain visible.
return {
  "sudo-tee/opencode.nvim",
  config = function()
    require("opencode").setup({})
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "saghen/blink.lib",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
        file_types = { 'markdown', 'opencode_output' },
      },
      ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
    },
    'saghen/blink.cmp',
    'folke/snacks.nvim',
  },
}
