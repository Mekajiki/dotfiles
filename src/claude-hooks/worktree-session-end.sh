#!/bin/sh
# Claude セッション終了時、cwd が .claude/worktrees/ 配下なら
# docker compose のリソース (containers, volumes, orphans) を削除する。
# cl-setup.sh が生成した compose.override.yml は auto-load されるので
# -f を渡さなくても override の name と port が反映される。
case "$PWD" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac

for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
  if [ -f "$f" ]; then
    docker compose down -v --remove-orphans 2>/dev/null
    exit 0
  fi
done
exit 0
