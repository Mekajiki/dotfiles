#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src

# Link dotfiles to $HOME
cd $HOME
ln -sfn $base_dir/.[a-z]* ./



# Claude Code config
mkdir -p $HOME/.claude
ln -sfn $base_dir/CLAUDE.md $HOME/.claude/

# settings.json は Claude が随時書き換えるので symlink せず、
# 初回 (or 過去の symlink が残っている場合) だけ .example からコピーする。
settings="$HOME/.claude/settings.json"
if [ -L "$settings" ] || [ ! -e "$settings" ]; then
  rm -f "$settings"
  cp "$base_dir/claude-settings.json.example" "$settings"
fi
