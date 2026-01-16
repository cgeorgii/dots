-- Haskell-specific configuration using haskell-tools.nvim
local ht = require('haskell-tools')
local wk = require('which-key')
local bufnr = vim.api.nvim_get_current_buf()

-- Setup Haskell-specific keybindings with which-key
wk.add({
  -- LSP navigation
  { "gd", vim.lsp.buf.definition, desc = "Go to definition", buffer = bufnr },
  { "gy", vim.lsp.buf.type_definition, desc = "Go to type definition", buffer = bufnr },
  { "gi", vim.lsp.buf.implementation, desc = "Go to implementation", buffer = bufnr },
  { "gr", vim.lsp.buf.references, desc = "Go to references", buffer = bufnr },
  { "<leader>k", vim.lsp.buf.hover, desc = "Display hover documentation", buffer = bufnr },
  { "<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol", buffer = bufnr },

  -- Code actions
  { "<leader>qq", vim.lsp.buf.code_action, desc = "Show code actions menu", buffer = bufnr },
  { "<space>ca", vim.lsp.buf.code_action, desc = "Show code actions", buffer = bufnr },
  { "<space>cl", vim.lsp.codelens.run, desc = "Run code lens", buffer = bufnr },

  -- Haskell-specific features
  { "<space>hs", ht.hoogle.hoogle_signature, desc = "Hoogle signature search", buffer = bufnr },
  { "<space>ea", ht.lsp.buf_eval_all, desc = "Evaluate all code lenses", buffer = bufnr },

  -- REPL integration
  { "<leader>rr", ht.repl.toggle, desc = "Toggle GHCi REPL", buffer = bufnr },
  { "<leader>rf", function()
    ht.repl.toggle(vim.api.nvim_buf_get_name(0))
  end, desc = "Toggle REPL for current file", buffer = bufnr },
  { "<leader>rq", ht.repl.quit, desc = "Quit REPL", buffer = bufnr },
})
