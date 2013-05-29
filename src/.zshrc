zstyle :compinstall filename '~/.zshrc'

# About ls command
export LSCOLORS=gxfxcxdxbxhggdabagacad
zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'ex=31' 'bd=37;46' 'cd=36;43'

# end About ls command

# z - jump around
#
if [[ -f ~/repos/z/z.sh ]] {
  . $HOME/repos/z/z.sh
  function precmd () {
    _z --add "$(pwd -P)"
  }
}

