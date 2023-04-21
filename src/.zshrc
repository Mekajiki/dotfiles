export LC_ALL="en_US.UTF-8"
export LANG="en_JP.UTF-8"

export FLEX_HOME=$HOME/sharedItems/flex_sdk_3.5.0.12683

export GOPATH=$HOME/go

export PATH=/usr/local/share/gradle/bin:$GOPATH/bin:/usr/local/go/bin:/usr/local/java/android-sdk/platform-tools:/usr/local/java/android-sdk/tools:/Users/administrator/Library/Haskell/ghc-7.0.3/lib/egison-0.2.1.1/bin:$HOME/sharedItems/bin:$HOME/bin:$FLEX_HOME/bin:/usr/local/sbin:/usr/local/Library/Sencha/Cmd/4.0.0.203/:/usr/local/bin:$PATH
export PATH=$HOME/Applications/android-studio/bin:$PATH
export PATH=/usr/local/share/scala/bin:$PATH
export PYTHONPATH=$HOME/caffe/python:$PYTHONPATH

sumContribution(){
  author=$2
  if [ -z "$author" ]; then author='ii.hsif.drows@gmail.com'; fi
  echo "Author: $author"
  git log --author=$author --shortstat --since=$1 |grep 'files\? changed' | awk '{files+=$1; inserted+=$4; deleted+=$6} END {print "files changed", files, "lines inserted:", inserted, "lines deleted:", deleted}'
}

#by os settings
case ${OSTYPE} in
  darwin*)
    setopt hist_ignore_dups share_history inc_append_history extended_history
    fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
    os_logo="🍎"
      ;;
  linux*)
    setopt hist_ignore_dups share_history inc_append_history
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
    os_logo="🐧"
      ;;
esac

#aliases
#
alias f='fg'
alias v='vim'
alias m='make'
alias ls="ls -Gv"
#git aliases
if (( $+commands[hub] )) {
  eval "$(hub alias -s)"
}
alias g='git'
alias gf='git flow'
alias gs='git status -s -b'
alias gb='git branch --color'
alias gco='git checkout'
alias ga='git add'
alias gl='git log'
alias gls='git ls-files | grep'
alias gc='git commit -v'
alias gst='git stash'
alias gpull='git pull'
alias gpush='git push'
alias gpushf='git push --force-with-lease'
alias gdif='git diff'
alias gg='git grep'
alias ggn='git grep --name-only'
alias grb='git rebase'
alias gpr='git pull-request --push --browse'

alias grm='git redmine'

alias today="sumContribution 1.day"
alias week="sumContribution 1.week"

alias d="docker-compose"
alias dr="docker-compose exec server rails"

alias fl="flutter"

alias tp="tmux show-buffer |pbcopy"

alias pomoi='pomo incomplete last'
alias pomoc='pomo complete'
alias pomos='pomo start'
alias pomob='pomo break'
alias pomoa='pomo add'

alias json='python -m json.tool'

alias prs='ps aux | grep'

alias dl='gradle'

alias node='nodejs'

# comp
#
autoload -Uz compinit
compinit
HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=1000000
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey -e
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# auto change directory
#
setopt auto_cd

# use #, ~, ^ as regexp in filename
#
setopt extended_glob

fpath=(~/.zsh $fpath)

# correct spell miss
#
setopt correct

# RSENSE
#
export RSENSE_HOME=$HOME/.vim/rsense
zstyle :compinstall filename '~/.zshrc'

# About ls command
#
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

# Prompt
#
local CYAN=$'%{\e[1;36m%}'
local YELLOW=$'%{\e[1;33m%}'
local DEFAULT=$'%{\e[1;32m%}'

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '%F{yellow}改'
precmd() {
  local format_string='%F{white}%b'$DEFAULT':'

  if [[ -n $(git ls-files --modified 2> /dev/null) ]] {
    format_string+=' %u'
  }

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]] {
    format_string+='%F{red}未'
  }
  format_string+=' '

  zstyle ':vcs_info:git*' formats $format_string
  vcs_info

  # set current dir as the name of tmux window
  if (tmux info &> /dev/null) {
    tmux set-window-option window-status-format " #I:${PWD:t} " > /dev/null
  }
}

setopt prompt_subst

PROMPT='%n'$YELLOW'@%M$os_logo :'$CYAN'%~%$
${vcs_info_msg_0_}'$DEFAULT'$ '
PROMPT2="%_%% "

## Gcloud
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mekajiki/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mekajiki/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/mekajiki/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mekajiki/google-cloud-sdk/completion.zsh.inc'; fi
[[ `which kubectl` ]] && source <(kubectl completion zsh)
[[ `which kubectl` ]] && source <(kubectl completion zsh)

## Pet
# Register the previous command
function prev() {
  PREV=$(fc -lrn | head -n 1)
  sh -c "pet new `printf %q "$PREV"`"
}

# alias
alias pe='pet exec'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
