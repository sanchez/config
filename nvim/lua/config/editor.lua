vim.pack.add({
    "https://github.com/romus204/referencer.nvim",
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/lewis6991/gitsigns.nvim",
    -- { src = "https://github.com/neoclide/coc.nvim", version = "release" },
    "https://github.com/akinsho/bufferline.nvim",
    "https://github.com/rafamadriz/friendly-snippets",
    "https://github.com/saghen/blink.cmp",
})

require("lualine").setup({
    options = {
        icons_enabled = true,
        theme = "auto",
    }
})

require("bufferline").setup({
    options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        numbers = "buffer_id",
    },
})

local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
    capabilities = capabilities
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
        },
    },
})

vim.lsp.enable("lua_ls")

local cmp = require("blink.cmp")
-- cmp.build():wait(60000)
cmp.setup({
    keymap = { preset = "default" },
    completion = { documentation = { auto_show = false } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "lua" },
    signature = { enabled = true },
})

-- Show diagnostics automatically when cursor rests on a line
vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
    end,
})

-- Controls how long before CursorHold fires (in ms), default is 4000
vim.opt.updatetime = 300

-- For some reason I have had issues where the lsp checks didn't run straight away. Copilot came up with this genius plan
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(args)
    local value = vim.tbl_get(args, "data", "params", "value")
    if value and value.kind == "end" and value.title == "Loading workspace" then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "lua_ls" then
        for buf, _ in pairs(client.attached_buffers) do
          client:notify("textDocument/didChange", {
            textDocument = {
              uri = vim.uri_from_bufnr(buf),
              version = vim.lsp.util.buf_versions[buf] or 0,
            },
            contentChanges = {
              { text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") }
            },
          })
        end
      end
    end
  end,
})

-- LSP-based document highlighting
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client and client:supports_method("textDocument/documentHighlight") then
            local augroup = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = args.buf,
                group = augroup,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd("CursorMoved", {
                buffer = args.buf,
                group = augroup,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})
