#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src

# Link dotfiles to $HOME
cd $HOME
ln -sfn $base_dir/.[a-z]* ./

# Link bin scripts to ~/bin
mkdir -p $HOME/bin
ln -sfn $base_dir/pull_request_with_prompt $HOME/bin/

# Link Claude Code config
mkdir -p $HOME/.claude
ln -sfn $base_dir/CLAUDE.md $HOME/.claude/
ln -sfn $base_dir/claude-settings.json $HOME/.claude/settings.json
