"todo:
"windows
"make
"cwd
"splitting
"https://shapeshed.com/vim-netrw/

let mapleader = "\<Space>"

if empty(glob('~/.vim/autoload/plug.vim'))
  silent execute '!curl -fLo ~/.vim/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'jiangmiao/auto-pairs'
Plug 'tomtom/tcomment_vim'
Plug 'ap/vim-css-color'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'mbbill/undotree'
Plug 'tpope/vim-repeat'
call plug#end()

nnoremap <Leader>p :CtrlP<CR>
let g:ctrlp_show_hidden = 1
let g:ctrlp_switch_buffer = 'e'
let g:ctrlp_follow_symlinks = 1



"  Improving Responsivenes.
set timeout timeoutlen=500 ttimeoutlen=100

" Use CTRL-L to clear the highlighting of 'hlsearch'.
nnoremap <silent> <C-L> :nohlsearch<Bar>diffupdate<CR><C-L>

" Shift is annoying sometimes
command! -nargs=0 W w
command! -nargs=0 WQ wq
command! -nargs=0 Wq wq

" Saving options in session and view files causes more problems than it solves.
set sessionoptions-=options
set viewoptions-=options

" Allow color schemes to do bright colors without forcing bold.
if &t_Co == 8 && $TERM !~# '^Eterm'
  set t_Co=16
endif

" Pretty standard toggles
syntax enable
filetype plugin indent on

set nocompatible
set noswapfile
set mouse=a
set clipboard=unnamedplus
set history=1000

set number
set relativenumber

set encoding=UTF-8
set shiftwidth=4
set autoindent
set smartindent
set wrap

set incsearch
set hlsearch
set smartcase
set ignorecase

set cursorline
set showbreak=↳
set noerrorbells
set background=dark

vnoremap > >gv
vnoremap < <gv

" Remember Folds
augroup remember_folds
  autocmd!
  au BufWinLeave ?* mkview 1
  au BufWinEnter ?* silent! loadview 1
augroup END

" Navigation Keymaps
noremap j h
noremap k j
noremap l k
noremap ; l

inoremap jk <esc>
inoremap ji <esc>:w<CR>i
inoremap ju <esc>:u<CR>i
inoremap jr <esc><C-r>i

" Execute Line
noremap Q !!$SHELL<CR>

" Window Configuration
set splitbelow     " Split horizontally at the bottom
set splitright     " Split vertically on the right

nnoremap <Leader>\| :vertical  CtrlP<CR>
nnoremap <Leader>- :split CtrlP<CR>

" Window Sizing
nnoremap <Leader>= <C-w>=   " Equalize window sizes
nnoremap <Leader><Up>    :resize -5<CR>   " Increase window height
nnoremap <Leader><Down>  :resize +5<CR>   " Decrease window height
nnoremap <Leader><Left>  :vertical resize -5<CR>   " Decrease window width
nnoremap <Leader><Right> :vertical resize +5<CR>   " Increase window width

" Buffer Navigation
nnoremap <Leader>bl :ls<CR>   " List open buffers
nnoremap <Leader>bn :bn<CR> " Switch to next buffer
nnoremap <Leader>bp :bp<CR> " Switch to previous buffer

nnoremap <leader>u :UndotreeToggle<CR>

nnoremap <A-Up> <C-W>k
nnoremap <A-Down> <C-W>j
nnoremap <A-Left> <C-W>h
nnoremap <A-Right> <C-W>l

nnoremap <leader>m :help<CR>
