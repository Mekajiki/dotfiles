#!/bin/sh
# Claude セッション終了時、cwd が .claude/worktrees/ 配下で
# cl-setup.sh が生成した compose.worktree.yml がある場合に
# docker compose のリソース (containers, volumes, orphans) を削除する。
case "$PWD" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac
[ -f compose.worktree.yml ] || exit 0

base=""
for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
  if [ -f "$f" ]; then
    base=$f
    break
  fi
done
[ -z "$base" ] && exit 0

docker compose -f "$base" -f compose.worktree.yml down -v --remove-orphans 2>/dev/null
exit 0
