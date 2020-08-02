# Lol Swag Yolo 9000 files
## The last do files I'm ever gonna need! Bay beeeee!

# Windows

**Terminal**

I'm using windows terminal for now until it pisses me off so bad I want to go back to cmdr

# dotfiles

---
```vimscript
" Startup text
  augroup hello_on_enter
    autocmd!
    autocmd VimEnter * echo "Jacking into the matrix..."
  augroup END
```

This is a simple greeting message. It says "Jacking into the matrix when you start up vim.

---
```vimscript
" Exit insert/visual mode easier
inoremap jk <esc>
vnoremap jk <esc>
```

Remaps the `jk` motion to the escape key in both insert and visual modes to make it so that you can use `jk` to exit these modes

---
```vimscript
" dotfile editing bindings
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
```

I'm using these to make it easy to edit and resource my dotfiles when I need to

---
```vimscript
" Turn on relative line numbers
set relativenumber
```

I like to have relative line numbers turned on it makes it easier to see what I'm yanking or deleting without having to resort to visual mode

---
```vimscript
" Remap leader
nnoremap <SPACE> <Nop>
let mapleader=" "
```

Remap the leader key to space because I ain't crazy!!

---
```vimscript
" Save convenience binding
nnoremap <leader>fs :w<cr>
nnoremap <leader>fS :wa<cr>
```

These binding are for convience they make saving files happen with one less keystroke and match doom emacs so I don't get confused if I want to flick betweent the two
