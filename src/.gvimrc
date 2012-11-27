" For Mac
" -------------------------------------------------------------
if has('gui_macvim')
    set guioptions=egmrt
    set guioptions-=r
    set guifont=Osaka-Mono:h16
    set fullscreen
    set transparency=15
    if has('kaoriya')
      set noimdisableactivate
      set clipboard=unnamed,autoselect
      noremap <C-v> "+p
    endif
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
