zstyle :compinstall filename '~/.zshrc'

# About ls command
#
export LSCOLORS=gxfxcxdxbxhggdabagacad
zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'ex=31' 'bd=37;46' 'cd=36;43'

# z - jump around
#
if [[ -d $HOME/repos/z ]] {
  . $HOME/repos/z/z.sh
  function precmd () {
  _z --add "$(pwd -P)"
  }
}

