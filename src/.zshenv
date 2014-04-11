export LC_ALL="en_US.UTF-8"
export LANG="en_JP.UTF-8"

export FLEX_HOME=$HOME/sharedItems/flex_sdk_3.5.0.12683

export PATH=/Users/administrator/Library/Haskell/ghc-7.0.3/lib/egison-0.2.1.1/bin:$HOME/sharedItems/bin:$HOME/bin:$FLEX_HOME/bin:/usr/local/sbin:$PATH

sumContribution(){
  gl --author=ii.hsif.drows@gmail.com --shortstat --since=$1 |grep 'changed.*insertions.*deletions' | awk '{files+=$1; inserted+=$4; deleted+=$6} END {print "files changed", files, "lines inserted:", inserted, "lines deleted:", deleted}'
}

#aliases
#
alias f='fg'
alias v='vim'
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
alias gc='git commit -v'
alias gst='git stash'
alias gpull='git pull'
alias gpush='git push'
alias gdif='git diff'
alias gg='git grep'
alias grb='git rebase'
alias gbr='git branch'
alias grm='git redmine'
alias today="sumContribution 1.day"
alias week="sumContribution 1.week"

# comp
#
autoload -Uz compinit
compinit
setopt hist_ignore_dups share_history inc_append_history extended_history
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

# no more escape for git carrets like HEAD^
#
if [[ -d $HOME/repos/zsh-git-escape-magic ]] {
  fpath=(~/repos/zsh-git-escape-magic ${fpath})
  autoload -Uz git-escape-magic
  git-escape-magic
}

# correct spell miss
#
setopt correct

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
}

setopt prompt_subst

PROMPT='%n'$YELLOW'@%M:'$CYAN'%~%$
${vcs_info_msg_0_}'$DEFAULT'$ '
PROMPT2="%_%% "

# RVM
#
if [[ -e $HOME/.rvm ]] {
  source $HOME/.rvm/scripts/rvm
}
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# RVM
#
export RSENSE_HOME=$HOME/.vim/rsense
