#!/bin/sh
# Claude が EnterWorktree で .claude/worktrees/<branch>/ に入った直後に呼ぶ想定。
# 当該 worktree に compose.worktree.yml を生成し、host port と
# docker compose project 名を branch ベースで決定的に分離する。
# branch 名は cwd の basename から導出。
set -e

cwd=`pwd`
case "$cwd" in
  */.claude/worktrees/*) ;;
  *)
    echo "cl-setup: not inside .claude/worktrees/, skipping." >&2
    exit 0
    ;;
esac

branch=`basename "$cwd"`

# main worktree の repo root から repo 名を取る (cwd の basename は branch 名なので別途)
common=`git rev-parse --git-common-dir`
case "$common" in
  /*) ;;
  *) common="$cwd/$common" ;;
esac
main_repo=`cd "$(dirname "$common")" && pwd`
repo_name=`basename "$main_repo"`

# branch 名から決定的に port を算出
if command -v sha1sum >/dev/null 2>&1; then
  hex=`printf '%s' "$branch" | sha1sum | cut -c1-4`
else
  hex=`printf '%s' "$branch" | shasum | cut -c1-4`
fi
hash=$((16#$hex))
server_port=$(( 20000 + (hash % 1000) ))
mailcatcher_port=$(( 21000 + (hash % 1000) ))
yard_port=$(( 22000 + (hash % 1000) ))
chrome_vnc_port=$(( 23000 + (hash % 1000) ))

# base compose の有無を確認
base=""
for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
  if [ -f "$f" ]; then
    base=$f
    break
  fi
done
if [ -z "$base" ]; then
  echo "cl-setup: no compose file in $cwd, skipping override generation." >&2
  exit 0
fi

# anipos 慣習 (service: server/mailcatcher/yard/chrome) を host port 分離する override。
# port と project 名はリテラル埋め込み (env 渡し不要)。
# 合致しない service は base に無いと docker compose 実行時にエラーになる。
cat > compose.worktree.yml <<EOF
name: ${repo_name}-${branch}
services:
  server:
    ports: !override
      - "${server_port}:3000"
  mailcatcher:
    ports: !override
      - "${mailcatcher_port}:1080"
  yard:
    ports: !override
      - "${yard_port}:8808"
  chrome:
    ports: !override
      - "${chrome_vnc_port}:5900"
EOF

cat <<EOF
cl-setup: compose.worktree.yml generated.
  project: ${repo_name}-${branch}
  server (Rails):  http://localhost:${server_port}
  mailcatcher:     http://localhost:${mailcatcher_port}
  yard:            http://localhost:${yard_port}
  chrome VNC:      vnc://localhost:${chrome_vnc_port}

Use both files together:
  docker compose -f ${base} -f compose.worktree.yml up -d
EOF
