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
          width = 50,
          height = 37
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
wk.add({
  { "<leader>a", "<cmd>ArgWrap<cr>", desc = "Wrap/Unwrap argument list" },

  { "<leader>b", group = "buffers" },
  { "<leader>bb", "<cmd>Buffers<cr>", desc = "Buffer picker" },
  { "<leader>bc", "<cmd>w ! wl-copy<cr><cr>", desc = "Copy content to clipboard" },
  { "<leader>bs", "<cmd>BLines<cr>", desc = "Fuzzy search current buffer" },

  { "<leader>c", group = "clipboard" },
  { "<leader>cc", "<cmd>ToggleClipboard<cr>", desc = "Toggle between editor/system clipboard" },

  { "<leader>r", group = "Reload/rename" },
  { "<leader>rr", "<cmd>e!<cr>", desc = "Reload current file" },
  { "<leader>rn", "<Plug>(coc-rename)", desc = "Rename current symbol" },

  { "<leader>C", group = "config" },
  { "<leader>CE", "<cmd>VimConfig<cr>", desc = "Edit vimconfig" },
  { "<leader>CR", "<cmd>source $MYVIMRC<cr>", desc = "Reload vimconfig" },

  { "<leader>f", group = "files" },
  { "<leader>ff", "<cmd>call CocActionAsync('format')<cr>", desc = "Format file" },
  { "<leader>f", "<Plug>(coc-format-selected)", desc = "Format selected", mode = "v" },
  { "<leader>f1", hidden = true },

  { "<leader>L", group = "LSP" },
  { "<leader>LR", "<cmd>CocRestart<cr><cr>", desc = "Reload LSP" },

  -- Tab management
  { "<leader>t", "<cmd>tabnew<cr>", desc = "New tab" },
  { "<leader>h", "<cmd>tabprevious<cr>", desc = "Previous tab" },
  { "<leader>l", "<cmd>tabnext<cr>", desc = "Next tab" },
  { "<leader>q", "<cmd>tabclose<cr>", desc = "Close tab" },

  -- Quickfix shortcuts
  { "<leader>n", "<Plug>(coc-diagnostic-next)", desc = "Next diagnostic" },
  { "<leader>N", "<Plug>(coc-diagnostic-prev)", desc = "Previous diagnostic" },
  { "<leader>p", "<cmd>call CocAction('diagnosticPrevious')<cr>", desc = "Previous diagnostic (alt)" },

  -- Quick fixes
  { "<leader>qf", "<Plug>(coc-fix-current)", desc = "Fix current" },
  { "<leader>qq", "<Plug>(coc-codeaction-cursor)", desc = "Code action" },

  { "<leader>k", "<cmd>call CocActionAsync('doHover')<cr>", desc = "Show documentation" },

  -- CocList commands
  { "<leader><space>", group = "CocList" },
  { "<leader><space>a", "<cmd>CocList diagnostics<cr>", desc = "Show all diagnostics" },
  { "<leader><space>e", "<cmd>CocList extensions<cr>", desc = "Manage extensions" },
  { "<leader><space>c", "<cmd>CocList commands<cr>", desc = "Show commands" },
  { "<leader><space>p", "<cmd>CocListResume<cr>", desc = "Resume latest coc list" },

  -- Goto mappings
  { "gd", "<Plug>(coc-definition)", desc = "Go to definition" },
  { "gy", "<Plug>(coc-type-definition)", desc = "Go to type definition" },
  { "gi", "<Plug>(coc-implementation)", desc = "Go to implementation" },
  { "gr", "<Plug>(coc-references)", desc = "Go to references" },

  -- Tmux navigation
  { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
  { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
  { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
  { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
})

-- Tmux navigation explicit mappings.
-- This is necessary to avoid a <C-\> conflict.
vim.g.tmux_navigator_no_mappings  = 1
