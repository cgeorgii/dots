vim.g.mapleader = ';'
vim.g.maplocalleader = ';'

vim.opt.writebackup = false -- No backup files
vim.opt.swapfile = false -- No swap files
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true -- Unless capital letter in search term
vim.opt.signcolumn = 'yes' -- Prevents screen jump on diagnostics
vim.opt.mouse = 'a' -- Enable scrolling with mouse inside tmux
vim.opt.showmode = false -- No need to show INSERT in command box
vim.opt.shortmess:append('I') -- Do not show welcome message
vim.opt.splitbelow = true -- More natural splits
vim.opt.splitright = true -- More natural splits
vim.opt.number = true -- Absolute line for current line
vim.opt.relativenumber = true -- Relative line numbers for others
vim.opt.incsearch = true

-- Import non-migrated vimscript config
vim.cmd('source ~/.config/nvim/legacy.vim')

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "vim", "vimdoc", "typescript", "tsx", "sql" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true
  }
}

require("nvim-tree").setup({
  view = {
    relativenumber = true,
    float = {
      enable = true,
      open_win_config = {
          width = 60,
          height = 40
        },
    },
  }
})

require('gitsigns').setup()

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'gruvbox',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {
      'branch',
    },
    lualine_b = {
      'diff',
      {
      'filename',
      path = 1,
      shorting_target = 30
      },
      {'diagnostics',
      -- Available sources are: --   'nvim_lsp', 'nvim_diagnostic', 'coc', 'ale', 'vim_lsp'.
      sources = { 'nvim_diagnostic', 'coc', 'ale' },
      sections = { 'error', 'warn', 'info', 'hint' },
      symbols = { error = ' ', warn = ' ', info = ' ' },
      colored = true,
      update_in_insert = true,
      always_visible = false,
    }
    },
    lualine_c = {},
    lualine_x = {'encoding'},
    lualine_y = {},
    lualine_z = {}
  },
  inactive_sections = {
    lualine_a = {
      'branch'
    },
    lualine_b = {
      'diff',
      {
      'filename',
      path = 1,
      shorting_target = 30
      },
      {'diagnostics',
      -- Available sources are: --   'nvim_lsp', 'nvim_diagnostic', 'coc', 'ale', 'vim_lsp'.
      sources = { 'nvim_diagnostic', 'coc', 'ale' },
      sections = { 'error', 'warn', 'info', 'hint' },
      symbols = { error = ' ', warn = ' ', info = ' ' },
      colored = true,
      update_in_insert = true,
      always_visible = false,
    }
    },
    lualine_c = {},
    lualine_x = {'encoding'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = { 'nerdtree' }
}

-- WhichKey Config
--
-- " Timeout
-- " Do not set a value too low, as it interferes with vim-commentary
vim.opt.timeoutlen = 500

local wk = require("which-key")

wk.setup {
  triggers_blacklist = {
  -- list of mode / prefixes that should never be hooked by WhichKey
  n = { "d", "v", "y", "g" }, -- TODO Do not ignore all "g"-prefixed, only gc for comments
  i = { "j", "k" },
  v = { "j", "k" },
},
}

wk.register({
  a = { "<cmd>ArgWrap<cr>", "Wrap/Unwrap argument list" },
  b = {
    name = "buffers",
    b = { "<cmd>Buffers<cr>", "Buffer picker" },
    c = { "<cmd>w ! wl-copy<cr><cr>", "Copy content to clipboard" },
    s = { "<cmd>BLines<cr>", "Fuzzy search current buffer" }
  },
  c = {
    name = "clipboard",
    c = { "<cmd>ToggleClipboard<cr>", "Toggle between editor/system clipboard" }
  },
  r = {
      name = "Reload/rename",
      r = { "<cmd>e!<cr>", "Reload current file" },
      n = { "<Plug>(coc-rename)", "Rename current symbol" }
  },
  C = {
    name = "config",
    E = { "<cmd>VimConfig<cr>", "Edit vimconfig" },
    R = { "<cmd>source $MYVIMRC<cr>", "Reload vimconfig" },
  },
  f = {
    name = "files",
    f = { "<cmd>call CocActionAsync('format')<cr>", "Format file" },
    ["1"] = "which_key_ignore",  -- special label to hide it in the popup TODO what why where
  },
  L = {
    name = "LSP",
    R = { "<cmd>CocRestart<cr><cr>", "Reload LSP" },
  },
  -- Tab management
  t = { "<cmd>tabnew<cr>", "New tab"},
  h = { "<cmd>tabprevious<cr>", "Previous tab"},
  l = { "<cmd>tabnext<cr>", "Next tab"},
  q = { "<cmd>tabclose<cr>", "Close tab"},
  -- Quickfix shortcuts
  n = { "<cmd>call CocAction('diagnosticNext')<cr>", "Next diagnostic" },
  p = { "<cmd>call CocAction('diagnosticPrevious')<cr>", "Previous diagnostic" },
}, { prefix = "<leader>" })

-- Tmux navigation explicit mappings.
-- This is necessary to avoid a <C-\> conflict.
vim.g.tmux_navigator_no_mappings  = 1
vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>')
vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>')
vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>')
vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>')
