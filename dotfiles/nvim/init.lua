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
    vim.fn.expand('~/.vim/undodir') -- Persistent undo directory
vim.opt.timeoutlen = 500            -- For which-key

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

---@diagnostic disable-next-line: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
  -- Theme
  {
    "RRethy/nvim-base16",
    priority = 1000, -- Load early
    config = function()
      vim.cmd('colorscheme base16-gruvbox-dark-medium')
    end,
  },

  -- UI enhancements
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'gruvbox',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
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
            { 'diagnostics',
              sources = { 'nvim_diagnostic', 'ale' },
              sections = { 'error', 'warn', 'info', 'hint' },
              symbols = { error = ' ', warn = ' ', info = ' ' },
              colored = true,
              update_in_insert = true,
              always_visible = false,
            }
          },
          lualine_c = {},
          lualine_x = {
            'encoding',
            { function() if IsSystemClipboard() then return "󰇄 System" else return "󰕷 Editor" end end,
              color = { fg = '#a3be8c' },
            }
          },
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
            { 'diagnostics',
              sources = { 'nvim_diagnostic', 'ale' },
              sections = { 'error', 'warn', 'info', 'hint' },
              symbols = { error = ' ', warn = ' ', info = ' ' },
              colored = true,
              update_in_insert = true,
              always_visible = false,
            }
          },
          lualine_c = {},
          lualine_x = { 'encoding' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        extensions = { 'nvim-tree' }
      }
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          relativenumber = true,
          float = {
            enable = true,
            open_win_config = { width = 50, height = 37 },
          },
        }
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
    end,
  },

  -- Improved diagnostics with Trouble
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup {
        position = "bottom",
        height = 10,
        icons = true,
        mode = "workspace_diagnostics",
        auto_preview = true,
        auto_close = false,
        use_diagnostic_signs = true
      }
    end,
  },

  -- WhichKey for keybindings
  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>a",  "<cmd>ArgWrap<cr>",                                                     desc = "Toggle argument wrapping (single/multi-line)" },

        { "<leader>b",  group = "Buffers" },

        { "<leader>bb", "<cmd>Buffers<cr>",                                                     desc = "Open buffer selector" },
        { "<leader>bc", "<cmd>w ! wl-copy<cr><cr>",                                             desc = "Copy entire buffer to system clipboard" },
        { "<leader>bs", "<cmd>BLines<cr>",                                                      desc = "Search within current buffer" },

        { "<leader>c",  group = "Clipboard" },
        { "<leader>cc", "<cmd>ToggleClipboard<cr>",                                             desc = "Toggle between vim and system clipboard" },

        { "<leader>r",  group = "Reload/Rename" },
        { "<leader>rr", "<cmd>e!<cr>",                                                          desc = "Reload current buffer from disk" },
        { "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>",                                    desc = "Rename symbol under cursor" },

        { "<leader>C",  group = "Config" },
        { "<leader>CE", "<cmd>VimConfig<cr>",                                                   desc = "Edit vim configuration file" },
        { "<leader>CR", "<cmd>Lazy sync<cr>",                                                   desc = "Reload plugins and configuration" },

        { "<leader>f",  group = "Formatting" },
        { "<leader>ff", "<cmd>lua vim.lsp.buf.format({ async = true })<cr>",                    desc = "Format entire file" },
        { "<leader>f",  "<cmd>lua vim.lsp.buf.format({ async = true })<cr>",                    desc = "Format visual selection",                     mode = "v" },
        { "<leader>f1", hidden = true },

        { "<leader>L",  group = "LSP" },
        { "<leader>LR", "<cmd>LspRestart<cr>",                                                  desc = "Restart language server" },
        { "<leader>Li", "<cmd>LspInfo<cr>",                                                     desc = "Show language server info" },
        { "<leader>LL", "<cmd>LspLog<cr>",                                                      desc = "Open LSP log" },

        -- FZF integration for searching
        { "<leader>s",  group = "Search" },
        { "<leader>sf", "<cmd>Files<cr>",                                                       desc = "Search files" },
        { "<leader>sg", "<cmd>Rg<cr>",                                                          desc = "Search with ripgrep" },
        { "<leader>sb", "<cmd>Buffers<cr>",                                                     desc = "Search buffers" },
        { "<leader>sh", "<cmd>Helptags<cr>",                                                    desc = "Search help tags" },
        { "<leader>sd", "<cmd>BLines<cr>",                                                      desc = "Search in current buffer" },

        -- Tab management
        { "<leader>t",  "<cmd>tabnew<cr>",                                                      desc = "Create new tab" },
        { "<leader>h",  "<cmd>tabprevious<cr>",                                                 desc = "Go to previous tab" },
        { "<leader>l",  "<cmd>tabnext<cr>",                                                     desc = "Go to next tab" },
        { "<leader>q",  "<cmd>tabclose<cr>",                                                    desc = "Close current tab" },

        -- Diagnostics navigation
        { "<leader>n",  "<cmd>lua vim.diagnostic.goto_next()<cr>",                              desc = "Jump to next diagnostic" },
        { "<leader>N",  "<cmd>lua vim.diagnostic.goto_prev()<cr>",                              desc = "Jump to previous diagnostic" },
        { "<leader>p",  "<cmd>lua vim.diagnostic.goto_prev()<cr>",                              desc = "Jump to previous diagnostic (alternative)" },

        -- Code actions
        { "<leader>qq", "<cmd>lua require('fzf-lua').lsp_code_actions()<cr>",                   desc = "Show code actions at cursor" },

        -- Documentation
        { "<leader>k",  "<cmd>lua vim.lsp.buf.hover()<cr>",                                     desc = "Display hover documentation" },

        -- Trouble (diagnostics viewer)
        { "<leader>xx", "<cmd>TroubleToggle<cr>",                                               desc = "Toggle trouble diagnostics" },
        { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",                         desc = "Show workspace diagnostics" },
        { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",                          desc = "Show document diagnostics" },
        { "<leader>xl", "<cmd>TroubleToggle loclist<cr>",                                       desc = "Show location list" },
        { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",                                      desc = "Show quickfix list" },
        { "<leader>xr", "<cmd>TroubleToggle lsp_references<cr>",                                desc = "Show references" },

        -- Tmux integration
        { "<C-h>",      "<cmd>TmuxNavigateLeft<cr>",                                            desc = "Navigate to left pane" },
        { "<C-j>",      "<cmd>TmuxNavigateDown<cr>",                                            desc = "Navigate to pane below" },
        { "<C-k>",      "<cmd>TmuxNavigateUp<cr>",                                              desc = "Navigate to pane above" },
        { "<C-l>",      "<cmd>TmuxNavigateRight<cr>",                                           desc = "Navigate to right pane" },

        -- Search and navigation
        { "K",          ":execute 'vimgrep /\\<'.expand('<cword>').'\\>/j **/*'<CR>:copen<CR>", desc = "Search word under cursor (to quickfix)" },
        { "K",          "y/<C-r>\"<CR>:vimgrep // **/*<CR>:copen<CR>",                          desc = "Search word under cursor (to quickfix)",      mode = "v" },
        { "<C-P>",      "<cmd>GFiles<cr>",                                                      desc = "Search Git tracked files" },
        { "<C-\\>",     "<cmd>Files<cr>",                                                       desc = "Search all files" },
        { "\\",         "<cmd>Rg!<cr>",                                                         desc = "Grep project" },
        { "H",          "^",                                                                    desc = "Jump to first non-blank character" },
        { "L",          "g_",                                                                   desc = "Jump to last non-blank character" },
        { "H",          "^",                                                                    desc = "Select to first non-blank character",         mode = "v" },
        { "L",          "g_",                                                                   desc = "Select to last non-blank character",          mode = "v" },
        { "*",          "#",                                                                    desc = "Search backward for exact word under cursor" },
        { "#",          "*",                                                                    desc = "Search forward for exact word under cursor" },

        -- File explorer
        { "<C-n>",      "<cmd>NvimTreeToggle<cr>",                                              desc = "Toggle file explorer" },
        { "<C-f>",      "<cmd>NvimTreeFindFile<cr>",                                            desc = "Locate current file in explorer" },

        -- LSP keymaps (converted from standard keymaps)
        { "gd",         "<cmd>lua vim.lsp.buf.definition()<cr>",                                desc = "Go to definition" },
        { "gy",         "<cmd>lua vim.lsp.buf.type_definition()<cr>",                           desc = "Go to type definition" },
        { "gi",         "<cmd>lua vim.lsp.buf.implementation()<cr>",                            desc = "Go to implementation" },
        { "gr",         "<cmd>lua vim.lsp.buf.references()<cr>",                                desc = "Go to references" },
        { "<space>rn",  "<cmd>lua vim.lsp.buf.rename()<cr>",                                    desc = "Rename symbol" },
        { "<space>ca",  "<cmd>lua vim.lsp.buf.code_action()<cr>",                               desc = "Show code actions" },
        { "<space>f",   "<cmd>lua vim.lsp.buf.format({ async = true })<cr>",                    desc = "Format code" },
      })
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "lua", "vim", "vimdoc", "typescript", "tsx", "sql", "haskell" },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        modules = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true
        }
      }
    end,
  },

  -- LSP and completion
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "onsails/lspkind.nvim",
    },

    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      -- Configure hover window border
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = "rounded"
        }
      )

      -- In your LSP config section
      vim.lsp.handlers["textDocument/codeAction"] = vim.lsp.with(
        vim.lsp.handlers.codeAction, {
          border = "rounded"
        }
      )

      -- Configure language servers
      -- TypeScript, JavaScript
      lspconfig.ts_ls.setup {
        capabilities = capabilities,
      }

      -- Lua
      lspconfig.lua_ls.setup {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
              enable = false,
            },
            format = {
              enable = true,
              -- Disable alignment of tables, keys, etc.
              defaultConfig = {
                align_table_field = false,
                align_assignment = false,
                align_array_table = false,
                align_continuous_assign_statement = false,
                align_continuous_rect_table_field = false,
                align_if_branch = false,
              }
            },
          },
        },
      }

      -- Elm
      lspconfig.elmls.setup {
        capabilities = capabilities,
      }

      -- Haskell (using haskell-language-server)
      lspconfig.hls.setup {
        capabilities = capabilities,
      }

      -- Setup nvim-cmp for completion
      local cmp = require 'cmp'
      local lspkind = require 'lspkind'

      cmp.setup({
        preselect = cmp.PreselectMode.Item,
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true
          }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' }
        }),
        formatting = {
          format = function(entry, vim_item)
            -- Get the icon and kind from lspkind
            local kind_icons = lspkind.cmp_format({
              mode = "symbol_text",
              maxwidth = 50,
            })

            -- Add the kind and icon
            vim_item = kind_icons(entry, vim_item)

            -- Add the source name
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]

            -- For LSP items, add the module/server name
            if entry.source.name == "nvim_lsp" then
              local client_name = entry.source.source.client.name or "LSP"
              vim_item.menu = string.format("%s [%s]", vim_item.menu, client_name)
            end

            -- Add details about the completion item
            if entry.completion_item.detail and entry.completion_item.detail ~= "" then
              vim_item.menu = string.format("%s • %s", vim_item.menu or "", entry.completion_item.detail)
            end

            return vim_item
          end
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        }
      })
    end,
  },
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    config = function()
      -- Use ripgrep if available for better performance
      if vim.fn.executable('rg') == 1 then
        -- Set ripgrep as the default grep program
        vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'

        -- Configure FZF to use ripgrep
        vim.g.fzf_default_command = 'rg --files --hidden --follow --glob "!.git/*"'

        -- Command for :Rg to respect .gitignore
        vim.g.rg_command =
        'rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '

        -- Use ripgrep for :Rg command
        vim.g.fzf_action = {
          ['ctrl-t'] = 'tab split',
          ['ctrl-s'] = 'split',
          ['ctrl-v'] = 'vsplit'
        }
      end

      -- Better preview with bat if available
      if vim.fn.executable('bat') == 1 then
        vim.g.fzf_preview_command = 'bat --style=numbers --color=always --line-range :500 {}'
      end

      -- Preview window options
      vim.g.fzf_preview_window = { 'right:50%', 'ctrl-/' }
    end,
  },
  {
    "ibhagwan/fzf-lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("fzf-lua").setup({
        winopts = {
          height = 0.85,
          width = 0.80,
          border = "rounded",
          preview = {
            border = "rounded",
            wrap = "nowrap",
            hidden = "nohidden",
          },
        },
      })
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    config = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
  },
  { "LnL7/vim-nix" },
  {
    "FooSoft/vim-argwrap",
    config = function()
      vim.g.argwrap_padded_braces = '{'
    end,
  },
  {
    "alvan/vim-closetag",
    config = function()
      vim.g.closetag_filenames = '*.html,*.xhtml,*.jsx,*.tsx,*.xml'
      vim.g.jsx_ext_required = 1
    end,
  },
  { "jiangmiao/auto-pairs" },
  { "mustache/vim-mustache-handlebars" },
  { "nelstrom/vim-visual-star-search" },
  { "neovimhaskell/haskell-vim" },
  { "ntpeters/vim-better-whitespace" },
  { "stephpy/vim-yaml" },
  { "tpope/vim-commentary" },
  { "tpope/vim-eunuch" },
  { "tpope/vim-repeat" },
  { "tpope/vim-surround" },
  {
    "dense-analysis/ale",
    config = function()
      vim.g.ale_pattern_options = { ['\\.hs$'] = { ale_enabled = 0 } }
    end,
  },
  { "isobit/vim-caddyfile" },
  { "vmchale/dhall-vim" },
  { "hashivim/vim-terraform" },
  { "github/copilot.vim" },
  {
    "dhruvasagar/vim-table-mode",
    config = function()
      vim.g.table_mode_corner_corner = '+'
      vim.g.table_mode_header_fillchar = '='
    end,
  },
}, {
  -- Lazy.nvim options
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    enabled = true,
    notify = true,
  },
})


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
