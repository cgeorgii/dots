-- Nix-specific LSP configuration
local wk = require('which-key')
local bufnr = vim.api.nvim_get_current_buf()

-- Setup LSP keybindings with which-key
wk.add({
  -- LSP navigation
  { "gd", vim.lsp.buf.definition, desc = "Go to definition", buffer = bufnr },
  { "gy", vim.lsp.buf.type_definition, desc = "Go to type definition", buffer = bufnr },
  { "gi", vim.lsp.buf.implementation, desc = "Go to implementation", buffer = bufnr },
  { "gr", vim.lsp.buf.references, desc = "Go to references", buffer = bufnr },
  { "<leader>k", vim.lsp.buf.hover, desc = "Display hover documentation", buffer = bufnr },
  { "<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol", buffer = bufnr },

  -- Code actions
  { "<space>ca", vim.lsp.buf.code_action, desc = "Show code actions", buffer = bufnr },
})
