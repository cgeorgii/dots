let mapleader = ";"
let maplocalleader = ";"

set encoding=utf-8
set backspace=indent,eol,start
set nobackup
set nowritebackup
set noswapfile
set ignorecase         " Case insensitive search
set smartcase          " Unless capital letter in search term
set inccommand=nosplit " Incremental search
set shortmess+=I       " Do not show welcome message
set signcolumn=yes     " Prevents screen jump on diagnostics
set mouse=a            " Enable scrolling with mouse inside tmux
set noshowmode         " No need to show -- INSERT -- in command box

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.local/share/nvim/plugged')

" Important
Plug 'LnL7/vim-nix'
Plug 'ElmCast/elm-vim'
Plug 'FooSoft/vim-argwrap'
Plug 'Yggdroot/indentLine'
Plug 'alvan/vim-closetag'
Plug 'christoomey/vim-tmux-navigator'
Plug 'mileszs/ack.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'
Plug 'mustache/vim-mustache-handlebars'
Plug 'nelstrom/vim-visual-star-search'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'leafgarland/typescript-vim'
Plug 'neovimhaskell/haskell-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'stephpy/vim-yaml'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'dense-analysis/ale'
Plug 'folke/which-key.nvim'
Plug 'RRethy/nvim-base16'
Plug 'lewis6991/gitsigns.nvim'
Plug 'isobit/vim-caddyfile'

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

lua <<END
require("nvim-tree").setup({
  view = {
    relativenumber = true,
    float = {
      enable = true,
      open_win_config = {
          width = 40,
          height = 32
        },
    },
  }
})
END

let g:table_mode_corner_corner='+'
let g:table_mode_header_fillchar='='

augroup YankHighlight
  autocmd!
  autocmd TextYankPost * silent! lua vim.highlight.on_yank()
augroup end

lua require('gitsigns').setup()

set termguicolors
let g:afterglow_inherit_background=1
colorscheme base16-gruvbox-dark-medium

lua << END
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'gruvbox_dark',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {
      'branch',
      'diff'
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
    lualine_x = {'encoding', 'fileformat', {'filetype', icon_only = true}},
    lualine_y = {},
    lualine_z = {}
  },
  inactive_sections = {
    lualine_a = {
      'branch',
      'diff'
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
    lualine_x = {'encoding', 'fileformat', {'filetype', icon_only = true}},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = { 'nerdtree' }
}
END

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
set regexpengine=1

" Use ag over grep
set grepprg=ag\ --nogroup\ --nocolor

" Display line numbers
set number rnu

" Search highlighting (real time and all results)
set hlsearch incsearch

" Sensible defaults for indentation
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
autocmd FileType elm setlocal softtabstop=4 shiftwidth=4 expandtab

" Enter paste mode
set pastetoggle=<F2>

" Open NvimTree with Ctrl+n
map <C-n> :NvimTreeToggle<CR>
" Find file in NvimTree with Ctrl+f
map <C-f> :NvimTreeFindFile<CR>

" Persistent undo between vim sessions
set undofile
set undodir=~/.vim/undodir

" More natural split
set splitbelow
set splitright

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

let g:jsx_ext_required = 1
au BufNewFile,BufRead *.ejs set filetype=html

augroup vimrc_autocmds
  autocmd BufWrite *.* StripWhitespace
  autocmd BufEnter * highlight OverLength cterm=underline guibg=#111111
  autocmd BufWrite *.rb call CocAction('format')
  autocmd BufWrite *.purs call CocAction('format')
augroup END

" indentLine config
let g:indentLine_char = '▏'

fun! ViewBundleGem ( gemName )
  let gemPath = system("RUBYOPT='-W0' bundle info --path " . a:gemName)
  if v:shell_error == 0
    echom "Opening gem: " . gemPath
    execute ":tabnew " . gemPath
    execute ":tcd " . gemPath
  else
    echom gemPath
  endif
endfun
command! -nargs=* ViewBundleGem call ViewBundleGem( "<args>" )

" Edit vim config
command! VimConfig :tabnew $MYVIMRC

fun! ToggleClipboard ()
  if &clipboard == 'unnamedplus'
    execute ':set clipboard='
    echom("Clipboard: EDITOR")
  else
    execute ':set clipboard=unnamedplus'
    echom("Clipboard: SYSTEM")
  endif
endfun
command! ToggleClipboard call ToggleClipboard()

" ArgWrap config
let g:argwrap_padded_braces = '{'

" -------------- Key maps
nnoremap \ :Ack!<Space>
nnoremap K :silent grep! <cword> \| copen<CR>
nnoremap \| :Tags<CR>
nnoremap <C-P> :GFiles<CR>
nnoremap <C-\> :Files<CR>
nnoremap <leader>bo :ViewBundleGem<SPACE>
nnoremap <leader>bp o(::Kernel.require 'pry'; ::Kernel.binding.pry)<ESC>
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>
nnoremap H ^
nnoremap L g_
vnoremap H ^
vnoremap L g_
nnoremap * #
nnoremap # *

" -------------- Git whichkey
" Timeout for which-key
" Do not set a value too low, as it interferes with vim-commentary
set timeoutlen=500

lua << EOF
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
    C = {
      name = "config",
      e = { "<cmd>VimConfig<cr>", "Edit vimconfig" },
      R = { "<cmd>source $MYVIMRC<cr>", "Reload vimconfig" },
    },
    e = { "<cmd>e!<cr>", "Reload current file" },
    f = {
      name = "files",
      r = { "<cmd>e!<cr>", "Reload current file" },
      F = { "<cmd>Telescope find_files<cr>", "Find file" },
      f = { "<cmd>call CocActionAsync('format')<cr>", "Format file" },
      ["1"] = "which_key_ignore",  -- special label to hide it in the popup TODO what why where
    },
  g = {
    name = "git",
    w = {
      name = "Worktrees",
        a = { function() require('telescope').extensions.git_worktree.create_git_worktree() end, "Add worktree" },
        l = { function() require('telescope').extensions.git_worktree.git_worktrees() end, "List worktrees" },
      },
  },
  L = {
    name = "LSP",
    R = { "<cmd>CocRestart<cr><cr>", "Reload LSP" },
  },
  r = { "<cmd>e!<cr>", "Reload file" },
  -- Tab management
  t = { "<cmd>tabnew<cr>", "New tab"},
  h = { "<cmd>tabprevious<cr>", "Previous tab"},
  l = { "<cmd>tabnext<cr>", "Next tab"},
  q = { "<cmd>tabclose<cr>", "Close tab"},
  -- Quickfix shortcuts
  n = { "<cmd>call CocAction('diagnosticNext')<cr>", "Next diagnostic" },
  N = {
    name = "Neorg",
    e = { "<cmd>Neorg gtd edit<cr>", "Edit todo" },
    v = { "<cmd>Neorg gtd views<cr>", "GTD Views" }
  },
  p = { "<cmd>call CocAction('diagnosticPrevious')<cr>", "Previous diagnostic" },
  s = {
    name = "Search functions",
    s = { "<cmd>Telescope live_grep<cr>", "Search for string" },
    t = { "<cmd>Ack! TODO<cr>", "Search for TODOS" }
    }
  }, { prefix = "<leader>" })
EOF
" -------------- Git whichkey

" Remap keys for gotos
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>qf <Plug>(coc-fix-current)
nmap <leader>qq <Plug>(coc-codeaction-cursor)
nmap <silent><leader>N <Plug>(coc-diagnostic-prev)
nmap <silent><leader>n <Plug>(coc-diagnostic-next)
" Use <leader>K to show documentation in preview window
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>

vmap <leader>f <Plug>(coc-format-selected)

" let g:ormolu_command="fourmolu"

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
" --------------------------------------------------------------------------

let g:elm_format_autosave = 1

" Run a given vim command on the results of alt from a given path.
" See usage below.
function! AltCommand(path, vim_command)
  let l:alternate = system("alt " . a:path)
  if empty(l:alternate)
    echo "No alternate file for " . a:path . " exists!"
  else
    exec a:vim_command . " " . l:alternate
  endif
endfunction

" Auto-run hpack on change
autocmd BufWritePost package.yaml call Hpack()
function Hpack()
  let err = system('hpack ' . expand('%'))
  if v:shell_error
    echo err
  endif
endfunction

" Find the alternate file for the current path and open it
nnoremap <leader>. :w<cr>:call AltCommand(expand('%'), ':e')<cr>

let g:ale_pattern_options = {'\.hs$': {'ale_enabled': 0}}
