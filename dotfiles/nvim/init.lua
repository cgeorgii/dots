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

-- Auto-install vim-plug if not present
local data_dir = vim.fn.stdpath('data') .. '/site'
local plug_path = data_dir .. '/autoload/plug.vim'

if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
  vim.fn.system({'curl', '-fLo', plug_path, '--create-dirs', 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'})
  vim.cmd('autocmd VimEnter * PlugInstall --sync | source $MYVIMRC')
end

-- Vim-plug configuration
vim.cmd([[
call plug#begin('~/.local/share/nvim/plugged')

" Important
Plug 'LnL7/vim-nix'
Plug 'ElmCast/elm-vim'
Plug 'FooSoft/vim-argwrap'
Plug 'alvan/vim-closetag'
Plug 'christoomey/vim-tmux-navigator'
Plug 'mileszs/ack.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'mustache/vim-mustache-handlebars'
Plug 'nelstrom/vim-visual-star-search'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neovimhaskell/haskell-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'stephpy/vim-yaml'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'dense-analysis/ale'
Plug 'folke/which-key.nvim'
Plug 'RRethy/nvim-base16'
Plug 'lewis6991/gitsigns.nvim'
Plug 'isobit/vim-caddyfile'
Plug 'vmchale/dhall-vim'
Plug 'hashivim/vim-terraform'
Plug 'github/copilot.vim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" lualine
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'
" /lualine

Plug 'kyazdani42/nvim-tree.lua'
Plug 'dhruvasagar/vim-table-mode'

" TODO - experimental stuff
Plug 'nvim-lua/plenary.nvim' " Is this still necessary?
Plug 'nvim-telescope/telescope.nvim'

call plug#end()
]])

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
  { "<leader>a", "<cmd>ArgWrap<cr>", desc = "Toggle argument wrapping (single/multi-line)" },

  { "<leader>b", group = "Buffers" },
  { "<leader>bb", "<cmd>Buffers<cr>", desc = "Open buffer selector" },
  { "<leader>bc", "<cmd>w ! wl-copy<cr><cr>", desc = "Copy entire buffer to system clipboard" },
  { "<leader>bs", "<cmd>BLines<cr>", desc = "Search within current buffer" },

  { "<leader>c", group = "Clipboard" },
  { "<leader>cc", "<cmd>ToggleClipboard<cr>", desc = "Toggle between vim and system clipboard" },

  { "<leader>r", group = "Reload/Rename" },
  { "<leader>rr", "<cmd>e!<cr>", desc = "Reload current buffer from disk" },
  { "<leader>rn", "<Plug>(coc-rename)", desc = "Rename symbol under cursor" },

  { "<leader>C", group = "Config" },
  { "<leader>CE", "<cmd>VimConfig<cr>", desc = "Edit vim configuration file" },
  { "<leader>CR", "<cmd>source $MYVIMRC<cr>", desc = "Reload vim configuration" },

  { "<leader>f", group = "Formatting" },
  { "<leader>ff", "<cmd>call CocActionAsync('format')<cr>", desc = "Format entire file" },
  { "<leader>f", "<Plug>(coc-format-selected)", desc = "Format visual selection", mode = "v" },
  { "<leader>f1", hidden = true },

  { "<leader>L", group = "LSP" },
  { "<leader>LR", "<cmd>CocRestart<cr><cr>", desc = "Restart language server" },

  -- Tab management
  { "<leader>t", "<cmd>tabnew<cr>", desc = "Create new tab" },
  { "<leader>h", "<cmd>tabprevious<cr>", desc = "Go to previous tab" },
  { "<leader>l", "<cmd>tabnext<cr>", desc = "Go to next tab" },
  { "<leader>q", "<cmd>tabclose<cr>", desc = "Close current tab" },

  -- Diagnostics navigation
  { "<leader>n", "<Plug>(coc-diagnostic-next)", desc = "Jump to next diagnostic" },
  { "<leader>N", "<Plug>(coc-diagnostic-prev)", desc = "Jump to previous diagnostic" },
  { "<leader>p", "<cmd>call CocAction('diagnosticPrevious')<cr>", desc = "Jump to previous diagnostic (alternative)" },

  -- Code actions
  { "<leader>qf", "<Plug>(coc-fix-current)", desc = "Apply quickfix for current issue" },
  { "<leader>qq", "<Plug>(coc-codeaction-cursor)", desc = "Show code actions at cursor" },

  { "<leader>k", "<cmd>call CocActionAsync('doHover')<cr>", desc = "Display hover documentation" },

  -- CocList commands
  { "<leader><space>", group = "CocList Menus" },
  { "<leader><space>a", "<cmd>CocList diagnostics<cr>", desc = "List all diagnostics" },
  { "<leader><space>e", "<cmd>CocList extensions<cr>", desc = "Manage CoC extensions" },
  { "<leader><space>c", "<cmd>CocList commands<cr>", desc = "Show available commands" },
  { "<leader><space>p", "<cmd>CocListResume<cr>", desc = "Resume last CoC list" },

  -- Code navigation
  { "gd", "<Plug>(coc-definition)", desc = "Go to symbol definition" },
  { "gy", "<Plug>(coc-type-definition)", desc = "Go to type definition" },
  { "gi", "<Plug>(coc-implementation)", desc = "Go to implementation" },
  { "gr", "<Plug>(coc-references)", desc = "Find all references" },

  -- Tmux integration
  { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate to left pane" },
  { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate to pane below" },
  { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate to pane above" },
  { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate to right pane" },

  -- Search and navigation
  { "K", "<cmd>silent grep! <cword> | copen<cr>", desc = "Grep for word under cursor" },
  { "<C-P>", "<cmd>GFiles<cr>", desc = "Search Git tracked files" },
  { "<C-\\>", "<cmd>Files<cr>", desc = "Search all files" },
  { "H", "^", desc = "Jump to first non-blank character" },
  { "L", "g_", desc = "Jump to last non-blank character" },
  { "H", "^", desc = "Select to first non-blank character", mode = "v" },
  { "L", "g_", desc = "Select to last non-blank character", mode = "v" },
  { "*", "#", desc = "Search backward for exact word under cursor" },
  { "#", "*", desc = "Search forward for exact word under cursor" },

  -- File explorer
  { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
  { "<C-f>", "<cmd>NvimTreeFindFile<cr>", desc = "Locate current file in explorer" },
})

-- Doesn't work with which-key. Find a better way to do this.
vim.keymap.set('n', '\\', ':Ack! ', { noremap = true, silent = false, desc = "Search with Ack" })

-- Tmux navigation explicit mappings.
-- This is necessary to avoid a <C-\> conflict.
vim.g.tmux_navigator_no_mappings  = 1

-- ArgWrap config
vim.g.argwrap_padded_braces = '{'

-- ALE pattern options
vim.g.ale_pattern_options = {['\\.hs$'] = {ale_enabled = 0}}

-- Table mode
vim.g.table_mode_corner_corner = '+'
vim.g.table_mode_header_fillchar = '='

-- Colorscheme config
vim.opt.termguicolors = true
vim.g.afterglow_inherit_background = 1
-- vim.cmd('colorscheme base16-gruvbox-light-medium')
vim.cmd('colorscheme base16-gruvbox-dark-medium')

-- Use ag if available
if vim.fn.executable('ag') == 1 then
  vim.g.ackprg = 'ag --vimgrep'
end

-- Use ag over grep
vim.opt.grepprg = 'ag --nogroup --nocolor'

-- Sensible defaults for indentation
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Persistent undo between vim sessions
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand('~/.vim/undodir')

-- JSX configuration
vim.g.jsx_ext_required = 1

-- File type associations
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
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

-- Toggle clipboard function
function ToggleClipboard()
  if vim.opt.clipboard:get()[1] == "unnamedplus" then
    vim.opt.clipboard = ""
    print("Clipboard: EDITOR")
  else
    vim.opt.clipboard = "unnamedplus"
    print("Clipboard: SYSTEM")
  end
end

vim.api.nvim_create_user_command('ToggleClipboard', ToggleClipboard, {})
