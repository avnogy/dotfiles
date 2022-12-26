set nocompatible              " be iMproved, required
filetype off                  " required

set bg=dark
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')"
"
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'preservim/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'sainnhe/sonokai' 
Plugin 'jiangmiao/auto-pairs'
Plugin 'tomtom/tcomment_vim'

"Plugin 'ayu-theme/ayu-vim' 
"Plugin 'vim-airline/vim-airline-themes'
" Plugin 'preservim/nerdcommenter'

"All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line


 """Important!!
if has('termguicolors')
  set termguicolors
endif
"atlantis, default, shusia, maia, amdromeda
let g:sonokai_style = 'atlantis'
let g:sonokai_better_performance = 1

colorscheme sonokai

let g:airline_theme = 'sonokai'

"set termguicolors     " enable true colors support
"let ayucolor="mirage"   "light, mirage, dark
"colorscheme ayu
"let g:airline_theme='hybrid'

set wrap
set noswapfile
set hlsearch
set ignorecase
set incsearch
set clipboard=unnamedplus
syntax enable

vnoremap > >gv
vnoremap < <gv

"toggle NERDTree
nnoremap <silent> <expr> <C-N> g:NERDTree.IsOpen() ? "\:NERDTreeClose<CR>" : bufexists(expand('%')) ? "\:NERDTreeFind<CR>" : "\:NERDTree<CR>"
" Start NERDTree. If a file is specified, move the cursor to its window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
