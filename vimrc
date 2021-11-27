set nocompatible

let mapleader = ";"
let maplocalleader = ";"

" Edit vim config
command! VimConfig :tabnew ~/.vimrc
map <silent> <leader>v :VimConfig<CR>

set encoding=utf-8
set backspace=indent,eol,start
set nobackup
set nowritebackup
set noswapfile
set ignorecase
set smartcase
set showcmd
set shortmess+=I
set signcolumn=yes
set lazyredraw
set inccommand=nosplit

nnoremap * #
nnoremap # *

" set rtp+=/usr/local/opt/fzf

filetype plugin indent on    " required

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.local/share/nvim/plugged')

Plug 'elixir-editors/vim-elixir'
Plug 'LnL7/vim-nix'
Plug 'ElmCast/elm-vim'
Plug 'FooSoft/vim-argwrap'
Plug 'Yggdroot/indentLine'
Plug 'alvan/vim-closetag'
Plug 'alx741/vim-hindent'
Plug 'chriskempson/base16-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'brookhong/ag.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-easy-align'
Plug 'mustache/vim-mustache-handlebars'
Plug 'nelstrom/vim-visual-star-search'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/vim-jsx-improve'
Plug 'neovimhaskell/haskell-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdtree'
Plug 'stephpy/vim-yaml'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-ruby/vim-ruby'
Plug 'vmchale/dhall-vim'
Plug 'w0rp/ale'
Plug 'wavded/vim-stylus'

call plug#end()

set regexpengine=1

" Use ag over grep
set grepprg=ag\ --nogroup\ --nocolor

" Display line numbers
set number rnu
set title

" Search highlighting (real time and all results)
set hlsearch incsearch

" Sensible defaults for indentation
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
autocmd FileType elm setlocal softtabstop=4 shiftwidth=4 expandtab


" Enter paste mode
set pastetoggle=<F2>

" set statusline="%f"
set laststatus=2

" Open NerdTree with Ctrl+n
map <C-n> :NERDTreeToggle<CR>

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
au BufNewFile,BufRead *.ts set filetype=javascript

autocmd BufWrite *.rb StripWhitespace

" indentLine config
let g:indentLine_char = '▏'

" ArgWrap config
nnoremap <silent> <leader>a :ArgWrap<CR>
let g:argwrap_padded_braces = '{'

fun! ViewBundleGem ( gemName )
  let gemPath = system("bundle info --path " . a:gemName)
  if v:shell_error == 0
    echom "Opening gem: " . gemPath
    execute ":tabnew " . gemPath
    execute ":tcd " . gemPath
  else
    echom gemPath
  endif
endfun
command! -nargs=* ViewBundleGem call ViewBundleGem( "<args>" )

fun! ToggleClipboard ()
  if &clipboard == 'unnamed'
    execute ':set clipboard='
  else
    execute ':set clipboard=unnamed'
  endif
  echom("clipboard set to: " . &clipboard)
endfun
command! ToggleClipboard call ToggleClipboard()
map <leader>cc :ToggleClipboard<CR>

" bind K to grep word under cursor
nnoremap K :silent grep! <cword> \| copen<CR>
nnoremap \ :Ag<SPACE>
" nnoremap \ :Ag<CR>
nnoremap \| :Tags<CR>
nnoremap <C-P> :Files<CR>
nnoremap <leader>; :Buffers<CR>
nnoremap <leader>r :e!<CR>
nnoremap <leader>R :source ~/.vimrc<CR>
nnoremap <leader>bo :ViewBundleGem<SPACE>
nnoremap <leader>bp o(::Kernel.require 'pry'; ::Kernel.binding.pry)<ESC>
nnoremap <leader>cb :!cat % \| pbcopy<CR><CR>
nnoremap <leader>n :cnext<CR>
nnoremap <leader>p :cprevious<CR>
nnoremap <leader>f gg=G<C-o><C-o>
nnoremap <leader>F :!rubocop % -a<CR><CR>
nnoremap <leader>s :%s/
nnoremap <leader>S :%S/
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>
nnoremap <silent> <leader>t :tabnew<CR>
nnoremap <silent> <leader>h :tabprevious<CR>
nnoremap <silent> <leader>l :tabnext<CR>
nnoremap <silent> <leader>q :tabclose<CR>


nnoremap H ^
nnoremap L g_
vnoremap H ^
vnoremap L g_

" --------------------------------------------------------------------------
" CoC configuration
" Use tab for trigger completion with characters ahead and navigate.
" " Use command ':verbose imap <tab>' to make sure tab is not mapped by other
" plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <C-l> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
inoremap <expr> <C-l>
      \ pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

inoremap jj <ESC>

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>qf  <Plug>(coc-fix-current)

" Use <leader>K to show documentation in preview window
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>

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

" Find the alternate file for the current path and open it
nnoremap <leader>. :w<cr>:call AltCommand(expand('%'), ':e')<cr>

let g:ale_pattern_options = {'\.hs$': {'ale_enabled': 0}}

set termguicolors
colorscheme base16-onedark
