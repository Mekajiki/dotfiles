" Vundle
" -------------------------------------------------------------
filetype off
set rtp+=~/.vim/vundle/
call vundle#rc()
" Plugins
" -------------------------------------------------------------
Bundle 'tpope/vim-rails'
Bundle 'ervandew/supertab'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-surround'
Bundle 'fatih/vim-go'
Bundle 'tpope/vim-sleuth'
Bundle 'tfnico/vim-gradle'
Bundle 'derekwyatt/vim-scala'
Bundle 'tpope/vim-bundler'
Bundle 'tpope/vim-pathogen'
Bundle 'slim-template/vim-slim'
Bundle 'junegunn/fzf'
Bundle 'junegunn/fzf.vim'
" Neovim Exclusive Plugins
" -------------------------------------------------------------
if has('nvim')
  Bundle 'github/copilot.vim'
endif
" General
" -------------------------------------------------------------
set enc=utf-8
set fileencodings=utf-8,iso-2022-jp,euc-jp,cp932,ucs-bom,default,latin1
set shell=zsh
set maxmempattern=8192
set autoread
filetype plugin on
filetype indent on
" For Mac
" -------------------------------------------------------------
if has('gui_macvim')
    set guioptions=egmrt
    set guioptions-=r
    set guifont=Osaka-Mono:h16
    set fullscreen
    set transparency=15
endif
" Display
" -------------------------------------------------------------
syntax on
set background=dark
colorscheme torte
set ruler
set ruf=%45(%12f%=\ %m%{'['.(&fenc!=''?&fenc:&enc).']'}\ %l-%v\ %p%%\ [%02B]%)
set showcmd
set cmdheight=1
set laststatus=2
set shortmess+=I
set nofoldenable
set vb t_vb=
set hlsearch
set number
set cursorline
" Spell check
set spell spelllang=en_us
setlocal spell spelllang=en_us
hi clear SpellBad
hi SpellBad cterm=underline
" Navigation
" -------------------------------------------------------------
noremap <C-j> 5gj
noremap <C-k> 5gk
" Emacs like navigation
" -------------------------------------------------------------
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-a> <Home>
cmap <C-e> <End>
imap <C-b> <Left>
omap <C-b> <Left>
imap <C-f> <Right>
omap <C-f> <Right>
imap <C-p> <Up>
imap <C-n> <Down>
omap <C-n> <Down>
inoremap <M-f> <C-o>e<Right>
vnoremap <M-f> e<Right>
onoremap <M-f> e<Right>
inoremap <M-b> <C-Left>
vnoremap <M-b> <C-Left>
onoremap <M-b> <C-Left>
imap <C-a> <ESC>^i
vmap <C-a> <Home>
omap <C-a> <Home>
imap <C-e> <End>
vmap <C-e> <End>
omap <C-e> <End>
inoremap <C-d> <Del>
cnoremap <C-d> <Del>
vnoremap <C-d> <Del>
onoremap <C-d> <Del>
inoremap <C-k> <C-o>D
" Editing
" -------------------------------------------------------------
set autoindent smartindent
set smarttab
set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
" File
" -------------------------------------------------------------
set wildmode=list:longest,full
if has('persistent_undo')
  set undodir=./.vimundo,~/.vimundo
  set undofile
endif
noremap ss :w<CR>
noremap qq :q<CR>
noremap <Space>. :<C-u>edit $MYVIMRC<Enter>
noremap <Space>s. :<C-u>source $MYVIMRC<Enter>
" Fugitive
" -------------------------------------------------------------
com! Gb Gblame
com! -nargs=+ Gg Git grep <args>
" Auto Exexuted Commands
" -------------------------------------------------------------
augroup Autocmds
  au BufNewFile *.sh call append(0, "#!/bin/sh")             | normal! G
  au BufNewFile *.py call append(0, "#!/usr/bin/env python") | normal! G
  au BufNewFile *.rb call append(0, "#!/usr/bin/env ruby") | normal! G
  au BufNewFile *.pl call append(0, "#!/usr/bin/env perl")   | normal! G
  au BufWritePost * silent! %s/\s\+$//e
" Other
" -------------------------------------------------------------
set backupdir=/tmp/
noremap tp :set paste!<CR>
"" fzf
" -------------------------------------------------------------
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.class
nnoremap <C-p> :GFiles<CR>
" Completion
" -------------------------------------------------------------
set history=700
set wildmenu
"" Gem-ctags
" -------------------------------------------------------------
autocmd FileType ruby let &l:tags = pathogen#legacyjoin(pathogen#uniq(
      \ pathogen#split(&tags) +
      \ map(split($GEM_PATH,':'),'v:val."/gems/*/tags"')))
