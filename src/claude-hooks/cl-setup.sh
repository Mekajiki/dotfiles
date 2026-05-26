#!/bin/sh
# Claude が EnterWorktree で .claude/worktrees/<branch>/ に入った直後に呼ぶ想定。
# 当該 worktree に compose.override.yml (auto-load 名) を生成し、
# host port と docker compose project 名を branch ベースで決定的に分離する。
# branch 名は cwd の basename から導出。
# auto-load 名にすることで `make up` や bare `docker compose up` でも override が効く。
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

# base compose を検出し、対応する auto-load override 名を決める
base=""
override=""
set -- \
  compose.yml         compose.override.yml \
  compose.yaml        compose.override.yaml \
  docker-compose.yml  docker-compose.override.yml \
  docker-compose.yaml docker-compose.override.yaml
while [ $# -ge 2 ]; do
  if [ -f "$1" ]; then
    base=$1
    override=$2
    break
  fi
  shift 2
done
if [ -z "$base" ]; then
  echo "cl-setup: no compose file in $cwd, skipping override generation." >&2
  exit 0
fi

# base に存在する service だけ override する (存在しない service を書くと
# compose が "service has neither image nor build context" でエラーになる)
existing=`docker compose -f "$base" config --services 2>/dev/null`

has_service() {
  echo "$existing" | grep -qx "$1"
}

emit_service() {
  name=$1
  host_port=$2
  target_port=$3
  if has_service "$name"; then
    cat <<EOF
  $name:
    ports: !override
      - "${host_port}:${target_port}"
EOF
  fi
}

{
  echo "name: ${repo_name}-${branch}"
  echo "services:"
  emit_service server      "$server_port"      3000
  emit_service mailcatcher "$mailcatcher_port" 1080
  emit_service yard        "$yard_port"        8808
  emit_service chrome      "$chrome_vnc_port"  5900
} > "$override"

# 出力 (Claude / 人間向けに port をサマリ)
echo "cl-setup: $override generated (auto-loaded by docker compose)."
echo "  project: ${repo_name}-${branch}"
has_service server      && echo "  server (Rails):  http://localhost:${server_port}"
has_service mailcatcher && echo "  mailcatcher:     http://localhost:${mailcatcher_port}"
has_service yard        && echo "  yard:            http://localhost:${yard_port}"
has_service chrome      && echo "  chrome VNC:      vnc://localhost:${chrome_vnc_port}"
echo
echo "Run with: docker compose up -d   (or 'make up')"
