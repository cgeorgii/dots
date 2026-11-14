-- <C-h/j/k/l> move between windows, then on into zellij panes at the edge.
-- zellij is locked while nvim is focused (autolock), so its own bindings
-- don't fire; this sends the same message to the meld plugin, which also
-- leaves a zoomed pane (modules/terminal/zellij/plugins/meld).
if vim.env.ZELLIJ == nil then
  return
end

local function nav(key, direction)
  return function()
    local win = vim.fn.winnr()
    vim.cmd.wincmd(key)
    if vim.fn.winnr() == win then
      vim.system({ "zellij", "pipe", "--plugin", "meld", "--name", "nav", "--", direction })
    end
  end
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", nav(key, direction), { silent = true, desc = "navigate " .. direction })
end
