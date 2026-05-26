#!/bin/sh
# Claude セッション開始時、cwd の git リポで
# 「origin にもう存在しない branch」に対応する worktree を掃除する。
#   - docker compose down -v --remove-orphans
#   - git worktree remove --force
#   - git branch -D
# GitHub の "Automatically delete head branches" が ON の前提。
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")
wt_dir="${repo_root}/.claude/worktrees"
[ -d "$wt_dir" ] || exit 0

git -C "$repo_root" fetch --prune origin 2>/dev/null

git -C "$repo_root" worktree list --porcelain \
  | awk '/^worktree / {print $2}' \
  | while read -r wt; do
      case "$wt" in
        "$wt_dir"/*) ;;
        *) continue ;;
      esac
      branch=$(basename "$wt")
      if git -C "$repo_root" ls-remote --heads origin "$branch" 2>/dev/null | grep -q .; then
        continue
      fi
      ( cd "$wt" && COMPOSE_PROJECT_NAME="${repo_name}-${branch}" \
          docker compose down -v --remove-orphans 2>/dev/null )
      git -C "$repo_root" worktree remove --force "$wt"
      git -C "$repo_root" branch -D "$branch" 2>/dev/null
    done
exit 0
