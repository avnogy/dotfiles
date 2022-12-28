set nocompatible              " be iMproved, required
filetype off                  " required

"install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"vim-plug
call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes
Plug 'VundleVim/Vundle.vim'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'sainnhe/sonokai' 
Plug 'jiangmiao/auto-pairs'
Plug 'tomtom/tcomment_vim'
Plug 'ap/vim-css-color'
Plug 'mbbill/undotree'

"Plugin 'ayu-theme/ayu-vim' 
"Plugin 'vim-airline/vim-airline-themes'
" Plugin 'preservim/nerdcommenter'

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()


:noremap Q !!$SHELL<CR>

augroup remember_folds
  autocmd!
  au BufWinLeave ?* mkview 1
  au BufWinEnter ?* silent! loadview 1
augroup END

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
set smartcase
set clipboard=unnamedplus
" set foldmethod=indent
" set foldnestmax=3

syntax enable

vnoremap > >gv
vnoremap < <gv

nnoremap <leader>u :UndotreeToggle<CR>

" toggle NERDTree
nnoremap <silent> <expr> <C-N> g:NERDTree.IsOpen() ? "\:NERDTreeClose<CR>" : bufexists(expand('%')) ? "\:NERDTreeFind<CR>" : "\:NERDTree<CR>"
" Start NERDTree. If a file is specified, move the cursor to its window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
