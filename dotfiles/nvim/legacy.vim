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

" Table mode
let g:table_mode_corner_corner='+'
let g:table_mode_header_fillchar='='

augroup YankHighlight
  autocmd!
  autocmd TextYankPost * silent! lua vim.highlight.on_yank()
augroup end

" Colorscheme config
set termguicolors
let g:afterglow_inherit_background=1
" colorscheme base16-gruvbox-light-medium
colorscheme base16-gruvbox-dark-medium

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" Use ag over grep
set grepprg=ag\ --nogroup\ --nocolor

" Sensible defaults for indentation
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" Elm config
autocmd FileType elm setlocal softtabstop=4 shiftwidth=4 expandtab
let g:elm_format_autosave = 1

" Open NvimTree with Ctrl+n
map <C-n> :NvimTreeToggle<CR>
" Find file in NvimTree with Ctrl+f
map <C-f> :NvimTreeFindFile<CR>

" Persistent undo between vim sessions
set undofile
set undodir=~/.vim/undodir

let g:jsx_ext_required = 1
au BufNewFile,BufRead *.ejs set filetype=html

augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength cterm=underline guibg=#111111
  autocmd BufWrite *.* StripWhitespace
  autocmd BufWrite *.rb call CocAction('format')
  " autocmd BufWritePost *.hs call CocAction('format')
  autocmd BufWritePost package.yaml call Hpack()
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
nnoremap <C-Bslash> :Files<CR>
nnoremap <leader>bo :ViewBundleGem<SPACE>
nnoremap <leader>bp o(::Kernel.require 'pry'; ::Kernel.binding.pry)<ESC>
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>
nnoremap H ^
nnoremap L g_
vnoremap H ^
vnoremap L g_
nnoremap * #
nnoremap # *

" Remap keys for gotos
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>qf <Plug>(coc-fix-current)
nmap <leader>qq <Plug>(coc-codeaction-cursor)
nmap <silent><leader>N <Plug>(coc-diagnostic-prev)
nmap <silent><leader>n <Plug>(coc-diagnostic-next)
" Use <leader>k to show documentation in preview window
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
nnoremap <silent> <leader><space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <leader><space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <leader><space>c  :<C-u>CocList commands<cr>
" Resume latest coc list
nnoremap <silent> <leader><space>p  :<C-u>CocListResume<CR>

" Auto-run hpack on change
function Hpack()
  let err = system('hpack ' . expand('%'))
  if v:shell_error
    echo err
  endif
endfunction

let g:ale_pattern_options = {'\.hs$': {'ale_enabled': 0}}
