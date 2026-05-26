#!/bin/sh
# Claude セッション終了時、cwd が .claude/worktrees/ 配下なら
# docker compose のリソース (containers, volumes, orphans) を削除する。
case "$PWD" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac

if [ -f compose.yml ] || [ -f compose.yaml ] \
  || [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then
  docker compose down -v --remove-orphans 2>/dev/null
fi
exit 0
