#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src

# Link dotfiles to $HOME
cd $HOME
ln -sfn $base_dir/.[a-z]* ./



# Link Claude Code config
mkdir -p $HOME/.claude
ln -sfn $base_dir/CLAUDE.md $HOME/.claude/
ln -sfn $base_dir/claude-settings.json $HOME/.claude/settings.json
