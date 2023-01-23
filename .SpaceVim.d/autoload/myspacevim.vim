function! myspacevim#after() abort
  :noremap Q !!$SHELL<CR>

  augroup remember_folds
    autocmd!
    au BufWinLeave ?* mkview 1
    au BufWinEnter ?* silent! loadview 1
  augroup END

  set wrap
  set noswapfile
  set hlsearch
  set ignorecase
  set smartcase
  set clipboard=unnamedplus
endfunction
