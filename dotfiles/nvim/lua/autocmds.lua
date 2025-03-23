-- File type associations
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.ejs",
  command = "set filetype=html"
})

-- Yank highlight
vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
    vim.highlight.on_yank()
  end
})

-- Miscellaneous autocmds
local vimrc_autocmds = vim.api.nvim_create_augroup("vimrc_autocmds", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = vimrc_autocmds,
  command = "highlight OverLength cterm=underline guibg=#111111"
})

vim.api.nvim_create_autocmd("BufWrite", {
  group = vimrc_autocmds,
  pattern = "*.*",
  command = "StripWhitespace"
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vimrc_autocmds,
  pattern = "package.yaml",
  callback = function()
    Hpack()
  end
})

-- Auto-run hpack on change
function Hpack()
  local err = vim.fn.system('hpack ' .. vim.fn.expand('%'))
  if vim.v.shell_error ~= 0 then
    print(err)
  end
end

-- Edit vim config
vim.api.nvim_create_user_command('VimConfig', 'tabnew $MYVIMRC', {})

-- IsSystemClipboard: Checks if system clipboard is active
-- @return boolean: true if system clipboard is active, false if editor clipboard
function IsSystemClipboard()
  local current_clipboard = vim.api.nvim_get_option_value("clipboard", {})
  return current_clipboard:find("unnamedplus") ~= nil
end

vim.api.nvim_create_user_command('ToggleClipboard', function()
  if IsSystemClipboard() then
    vim.opt.clipboard = ""
  else
    vim.opt.clipboard = "unnamedplus"
  end
end, {})
