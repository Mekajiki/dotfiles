" Vundle
" -------------------------------------------------------------
filetype off
set rtp+=~/.vim/vundle/
call vundle#rc()
" Plugins
" -------------------------------------------------------------
Bundle 'https://github.com/vim-scripts/syntaxhaskell.vim'
Bundle 'https://github.com/tpope/vim-rails/'
Bundle 'https://github.com/ervandew/supertab'
Bundle 'https://github.com/kien/ctrlp.vim.git'
Bundle 'https://github.com/tpope/vim-endwise.git'
Bundle 'https://github.com/kchmck/vim-coffee-script.git'
Bundle 'Shougo/neocomplcache.git'
Bundle 'Shougo/neosnippet-snippets.git'
Bundle 'https://github.com/Shougo/neosnippet.git'
Bundle 'https://github.com/vim-scripts/VimClojure'
Bundle 'https://github.com/drupal/drupal.git'
Bundle 'https://github.com/tpope/vim-fugitive.git'
Bundle 'https://github.com/tpope/vim-surround'
Bundle 'fatih/vim-go'
Bundle 'tpope/vim-sleuth'
" General
" -------------------------------------------------------------
set enc=utf-8
set fileencodings=utf-8,iso-2022-jp,euc-jp,cp932,ucs-bom,default,latin1
set shell=zsh
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
"" CtrlP
" -------------------------------------------------------------
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = '\v[\/](\.git|\.hg|\.svn)$'
" PHP highlighting
" -------------------------------------------------------------
if has("autocmd")
    " Drupal *.module and *.install files.
    augroup module
      autocmd BufRead,BufNewFile *.module set filetype=php
      autocmd BufRead,BufNewFile *.install set filetype=php
      autocmd BufRead,BufNewFile *.test set filetype=php
      autocmd BufRead,BufNewFile *.inc set filetype=php
      autocmd BufRead,BufNewFile *.profile set filetype=php
      autocmd BufRead,BufNewFile *.view set filetype=php
      autocmd BufRead,BufNewFile *.view set filetype=haml
    augroup END
    autocmd FileType php setlocal expandtab shiftwidth=2 softtabstop=2
    autocmd FileType python setlocal expandtab shiftwidth=2 softtabstop=2
endif
" Completion
" -------------------------------------------------------------
set history=700
set wildmenu
" Rsense
let g:rsenseUseOmniFunc = 1
let g:rsenseHome = expand('~/.vim/rsense')
" NeoSnippet
imap <C-q>     <Plug>(neosnippet_expand_or_jump)
smap <C-q>     <Plug>(neosnippet_expand_or_jump)

imap <expr><TAB> neosnippet#expandable() ? "\<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

if has('conceal')
  set conceallevel=2 concealcursor=i
endif

nmap <silent> ; :set opfunc=ReplaceWithRegister<CR>g@
vmap <silent> ; :<C-U>call ReplaceWithRegister(visualmode(), 1)<CR>

function! ReplaceWithRegister(type, ...)
  let sel_save = &selection
  let &selection = "inclusive"
  let reg_a = @a
  let reg_z = @z
  let @z = @@

  if a:0  " Invoked from Visual mode, use '< and '> marks.
    silent exe 'normal! `<' . a:type . '`>"ad"zP'
  elseif a:type == 'line'
    silent exe "normal! '[V']\"ad\"zP"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]\"ad`[\"zP"
  else
    silent exe 'normal! `["ad`]"Ax"zP'
  endif

  let &selection = sel_save
  let @@ = @a
  let @a = reg_a
  let @z = reg_z
endfunction

"" Scouter
" -------------------------------------------------------------
function! Scouter(file, ...)
  let pat = '^\s*$\|^\s*"'
  let lines = readfile(a:file)
  if !a:0 || !a:1
    let lines = split(substitute(join(lines, "\n"), '\n\s*\\', '', 'g'), "\n")
  endif
  return len(filter(lines,'v:val !~ pat'))
endfunction
command! -bar -bang -nargs=? -complete=file Scouter
\        echo Scouter(empty(<q-args>) ? $MYVIMRC : expand(<q-args>), <bang>0)
command! -bar -bang -nargs=? -complete=file GScouter
\        echo Scouter(empty(<q-args>) ? $MYGVIMRC : expand(<q-args>), <bang>0)
