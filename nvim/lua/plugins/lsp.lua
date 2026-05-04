return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    vim.lsp.config.rust_analyzer = {
      capabilities = capabilities,
      settings = {
        cargo = {
          allFeatures = true,
        },
        checkOnSave = {
          command = "clippy",
        },
      },
    }

    vim.lsp.config.pyright = {
      capabilities = capabilities,
      cmd = { vim.fn.expand("$HOME/.local/bin/pyright-langserver"), "--stdio" },
      filetypes = { "python" },
      root_pattern = function(pattern)
        return vim.fs.root(vim.api.nvim_buf_get_name(0), pattern)
      end,
      settings = {
        pyright = {
          analysis = {
            autoSearchPaths = true,
            typeCheckingMode = "basic",
            diagnosticSeverity = "information",
          },
        },
      },
    }

    vim.lsp.enable("rust_analyzer")
    vim.lsp.enable("pyright")

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
  end,
}