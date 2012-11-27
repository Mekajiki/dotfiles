export LANG=ja_JP.UTF-8

export FLEX_HOME=$HOME/sharedItems/flex_sdk_3.5.0.12683

export PATH=/Users/administrator/Library/Haskell/ghc-7.0.3/lib/egison-0.2.1.1/bin:$HOME/sharedItems/bin:$HOME/bin:$FLEX_HOME/bin:/usr/local/sbin:$PATH
source $HOME/.rvm/scripts/rvm

#aliases
#
alias f='fg'
alias ls="ls -Gv"
#git aliases
eval "$(hub alias -s)"
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
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# auto change directory
#
setopt auto_cd

# z - jump around
#
. $HOME/repos/z/z.sh
        function precmd () {
          _z --add "$(pwd -P)"
        }

# use #, ~, ^ as regexp in filename
#
setopt extended_glob

# no more escape for git carrets like HEAD^
#
fpath=(~/repos/zsh-git-escape-magic ${fpath})
autoload -Uz git-escape-magic
git-escape-magic
 
# correct spell miss
#
setopt correct

# Prompt
local CYAN=$'%{\e[1;36m%}'
local YELLOW=$'%{\e[1;33m%}'
local DEFAULT=$'%{\e[1;32m%}'
PROMPT='%n'$YELLOW'@%M:'$CYAN'%~%$ '$DEFAULT'
$ '
PROMPT2="%_%% "
# end Prompt

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

export RSENSE_HOME=$HOME/.vim/rsense 
