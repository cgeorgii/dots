set nocompatible " be iMproved, required

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

nnoremap * #
nnoremap # *

set rtp+=/usr/local/opt/fzf

filetype plugin indent on    " required

call plug#begin('~/.local/share/nvim/plugged')

Plug 'ElmCast/elm-vim'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'VundleVim/Vundle.vim'
Plug 'brookhong/ag.vim'
Plug 'christoomey/vim-tmux-navigator'
" Plug 'itchyny/lightline.vim'
" Plug 'itchyny/vim-gitbranch'
Plug 'junegunn/vim-easy-align'
Plug 'nelstrom/vim-visual-star-search'
Plug 'neoclide/vim-jsx-improve'
Plug 'neovimhaskell/haskell-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdtree'
Plug 'townk/vim-autoclose'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-ruby/vim-ruby'
Plug 'wavded/vim-stylus'
Plug 'alvan/vim-closetag'
Plug 'chriskempson/base16-vim'
Plug 'stephpy/vim-yaml'
Plug 'Yggdroot/indentLine'
Plug 'FooSoft/vim-argwrap'
Plug 'junegunn/fzf.vim'
Plug 'w0rp/ale'
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': './install.sh'}

call plug#end()

" let g:shell_colorscheme = system('echo $BASE16_THEME')
" execute('colorscheme ' . g:shell_colorscheme)
if filereadable(expand("~/.vimrc_background"))
  " let base16colorspace=256
  source ~/.vimrc_background
endif
set termguicolors

function! ShowFileName()
  return @%
endfunction

let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'paste' ],
      \             [ 'readonly', 'gitbranch', 'folderfile', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name',
      \   'folderfile': 'ShowFileName'
      \ },
      \ }

let g:ruby_path = system('echo $HOME/.rbenv/shims')
set regexpengine=1

" Use ag over grep
set grepprg=ag\ --nogroup\ --nocolor

" bind K to grep word under cursor
nnoremap K :silent grep! <cword> \| copen<CR>

" bind \ (backward slash) to grep shortcut
nnoremap \ :Ag<SPACE>

" Display line numbers
set number rnu
set title

" Search highlighting (real time and all results)
set hlsearch incsearch

" Sensible defaults for indentation
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" Enter paste mode
set pastetoggle=<F2>

set statusline+=%f
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

augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength cterm=underline guibg=#111111
  autocmd BufEnter * match OverLength /\%91v.*/
augroup END

let g:jsx_ext_required = 1

au BufNewFile,BufRead *.ejs set filetype=html
au BufNewFile,BufRead *.ts set filetype=javascript

autocmd BufWrite *.rb StripWhitespace

" indentLine config
let g:indentLine_char = '▏'

" ArgWrap config
nnoremap <silent> <leader>a :ArgWrap<CR>
let g:argwrap_padded_braces = '{'

" Tab navigation shortcuts
map <silent> <leader>t :tabnew<CR>
map <silent> <leader>h :tabprevious<CR>
map <silent> <leader>l :tabnext<CR>
map <silent> <leader>q :tabclose<CR>

fun! ViewBundleGem ( gemName )
  let a:gemPath = system("bundle info --path " . a:gemName)
  echom "Opening gem: " . a:gemPath

  execute ":tabnew " . a:gemPath
  set title a:gemName
endfun
command! -nargs=* ViewBundleGem call ViewBundleGem( "<args>" )

map <C-P> :Files<CR>
map <leader>; :Commands<CR><SPACE>
map <leader>R :source ~/.vimrc<CR>
map <leader>bo :ViewBundleGem<SPACE>
map <leader>bp o::Kernel.require 'pry'; ::Kernel.binding.pry<ESC>
map <leader>cb :!cat % \| pbcopy<CR><CR>
map <leader>n :cnext<CR>
map <leader>p :cprevious<CR>

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

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use <leader>K to show documentation in preview window
nnoremap <silent><leader>k :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
"
" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
" --------------------------------------------------------------------------
