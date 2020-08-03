" Startup text
  augroup hello_on_enter
    autocmd!
    autocmd VimEnter * echo "Jacking into the matrix..."
  augroup END

" Exit insert/visual mode easier
inoremap jk <esc>
vnoremap jk <esc>

" Turn on relative line numbers
set relativenumber

" Remap leader
nnoremap <SPACE> <Nop>
let mapleader=" "

" dotfile editing bindings
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" Save convenience binding
nnoremap <leader>fs :w<cr>
nnoremap <leader>fS :wa<cr>

" vim-plug keybindings
nnoremap <leader>PI :PlugInstall<cr>
nnoremap <leader>PC :PlugClean<cr>
nnoremap <leader>PU :PlugUpdate<cr>

" Begin plugins
call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'

call plug#end()
