#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src

# Link dotfiles to $HOME
cd $HOME
ln -sfn $base_dir/.[a-z]* ./



# Ghostty config (config.ghostty は 1.2.3 以降の正式名。XDG パスなら mac/Linux 共通)
mkdir -p $HOME/.config/ghostty
ln -sfn $base_dir/ghostty/config.ghostty $HOME/.config/ghostty/config.ghostty

# Claude Code config
mkdir -p $HOME/.claude
ln -sfn $base_dir/CLAUDE.md $HOME/.claude/

# Claude Code hooks
mkdir -p $HOME/.claude/hooks
for hook in $base_dir/claude-hooks/*.sh; do
  [ -e "$hook" ] || continue
  ln -sfn "$hook" $HOME/.claude/hooks/
done

# Claude Code skills (ディレクトリ単位で symlink。各 skill は <name>/SKILL.md)
mkdir -p $HOME/.claude/skills
for skill in $base_dir/claude-skills/*/; do
  [ -d "$skill" ] || continue
  ln -sfn "${skill%/}" $HOME/.claude/skills/
done

# settings.local.json は Claude 本体が書き込まないので symlink して dotfiles から管理する。
# permissions / enabledPlugins / hooks 等の dotfiles で同期したい設定はここに置く。
# settings.json と Claude Code 側でマージされ、scalar は settings.local が優先、
# array は連結+重複排除、object は deep merge される。
ln -sfn "$base_dir/claude-settings.local.json" "$HOME/.claude/settings.local.json"
