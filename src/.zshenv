# .zshenv
# Loaded by all zsh shells (interactive and non-interactive)
# Environment variables and PATH should be set here

export LC_ALL="en_US.UTF-8"
export LANG="en_JP.UTF-8"

export FLEX_HOME=$HOME/sharedItems/flex_sdk_3.5.0.12683

export GOPATH=$HOME/go

export PATH=/usr/local/bin:$HOME/bin:$PATH
export PATH=$HOME/Applications/android-studio/bin:$PATH

#by os settings
case ${OSTYPE} in
  darwin*)
    export PATH=/opt/homebrew/bin:$PATH
      ;;
  linux*)
      ;;
esac

# RSENSE
#
export RSENSE_HOME=$HOME/.vim/rsense

# About ls command
#
export LSCOLORS=gxfxcxdxbxhggdabagacad

export NVM_DIR="$HOME/.nvm"

# Load cargo environment if it exists
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mekajiki/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mekajiki/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/mekajiki/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mekajiki/Downloads/google-cloud-sdk/path.zsh.inc'; fi
