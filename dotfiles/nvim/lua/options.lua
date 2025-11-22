vim.g.mapleader = ';'               -- Set leader key
vim.g.maplocalleader = ';'          -- Set local leader key
vim.opt.writebackup = false         -- No backup files
vim.opt.swapfile = false            -- No swap files
vim.opt.ignorecase = true           -- Case insensitive search
vim.opt.smartcase = true            -- Unless capital letter in search term
vim.opt.signcolumn = 'yes'          -- Prevents screen jump on diagnostics
vim.opt.mouse = 'a'                 -- Enable scrolling with mouse inside tmux
vim.opt.showmode = false            -- No need to show INSERT in command box
vim.opt.shortmess:append('I')       -- Do not show welcome message
vim.opt.splitbelow = true           -- More natural splits
vim.opt.splitright = true           -- More natural splits
vim.opt.number = true               -- Absolute line for current line
vim.opt.relativenumber = true       -- Relative line numbers for others
vim.opt.incsearch = true            -- Incremental search
vim.opt.termguicolors = true        -- Enable true color support
vim.opt.tabstop = 2                 -- Sensible defaults for indentation
vim.opt.softtabstop = 2             -- Sensible defaults for indentation
vim.opt.shiftwidth = 2              -- Sensible defaults for indentation
vim.opt.expandtab = true            -- Use spaces for tabs
vim.opt.undofile = true             -- Persistent undo between vim sessions
vim.opt.undodir =
vim.fn.expand('~/.vim/undodir')     -- Persistent undo directory
vim.opt.clipboard = 'unnamedplus'   -- Use system clipboard by default
vim.opt.timeoutlen = 500            -- For which-key
vim.opt.title = true                -- Set terminal title
vim.opt.titlestring = 'nvim %t'     -- Title format: "nvim filename"
