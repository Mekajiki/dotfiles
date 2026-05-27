#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src

# Link dotfiles to $HOME
cd $HOME
ln -sfn $base_dir/.[a-z]* ./



# Claude Code config
mkdir -p $HOME/.claude
ln -sfn $base_dir/CLAUDE.md $HOME/.claude/

# Claude Code hooks
mkdir -p $HOME/.claude/hooks
for hook in $base_dir/claude-hooks/*.sh; do
  [ -e "$hook" ] || continue
  ln -sfn "$hook" $HOME/.claude/hooks/
done

# settings.json は Claude が随時書き換えるので symlink せず、
# 初回 (or 過去の symlink が残っている場合) だけ .example からコピーする。
settings="$HOME/.claude/settings.json"
if [ -L "$settings" ] || [ ! -e "$settings" ]; then
  rm -f "$settings"
  cp "$base_dir/claude-settings.json.example" "$settings"
fi

# settings.local.json は Claude 本体が書き込まないので symlink して dotfiles から管理する。
# hooks のような「dotfiles で同期したい」設定はここに置く。settings.json と配列マージされる。
ln -sfn "$base_dir/claude-settings.local.json" "$HOME/.claude/settings.local.json"
