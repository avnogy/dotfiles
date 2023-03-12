function! myspacevim#after() abort
  :noremap Q !!$SHELL<CR>

  " augroup remember_folds
    " autocmd!
    " au BufWinLeave ?* mkview 1
    " au BufWinEnter ?* silent! loadview 1
  " augroup END

  set relativenumber
  set wrap
  set noswapfile
  set hlsearch
  set encoding=UTF-8
  set ignorecase
  set shiftwidth=4
  set smartcase
  set clipboard=unnamedplus

  echo "loaded myspacevim"
endfunction
