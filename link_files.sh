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

# settings.local.json は Claude 本体が書き込まないので symlink して dotfiles から管理する。
# permissions / enabledPlugins / hooks 等の dotfiles で同期したい設定はここに置く。
# settings.json と Claude Code 側でマージされ、scalar は settings.local が優先、
# array は連結+重複排除、object は deep merge される。
ln -sfn "$base_dir/claude-settings.local.json" "$HOME/.claude/settings.local.json"
