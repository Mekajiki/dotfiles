#!/bin/sh
# Claude セッション開始時、cwd の git リポで
# 「origin にもう存在しない、かつ merged PR がある」branch に対応する worktree を
# 掃除する。具体的には:
#   - docker compose down -v --remove-orphans
#   - git worktree remove --force
#   - git branch -D
# GitHub の "Automatically delete head branches" が ON、かつ
# squash merge が標準の repo を前提に gh CLI で merged PR の有無を確認する。
# branch 名は `git worktree list --porcelain` の `branch refs/heads/<name>` から取る。
# Claude の EnterWorktree は dir basename と異なる branch 名 (worktree-<name>) を
# 作るので、dir basename を branch 名として扱うのは誤り。
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
repo_root=$(git rev-parse --show-toplevel)
wt_dir="${repo_root}/.claude/worktrees"
[ -d "$wt_dir" ] || exit 0

git -C "$repo_root" fetch --prune origin 2>/dev/null

git -C "$repo_root" worktree list --porcelain \
  | awk '
      /^worktree / { wt = $2; branch = "" }
      /^branch refs\/heads\// { branch = substr($2, 12); print wt "|" branch }
    ' \
  | while IFS='|' read -r wt branch; do
      case "$wt" in
        "$wt_dir"/*) ;;
        *) continue ;;
      esac
      [ -z "$branch" ] && continue
      # 条件A: origin にまだあるなら保護
      if git -C "$repo_root" ls-remote --heads origin "$branch" 2>/dev/null | grep -q .; then
        continue
      fi
      # 条件B: merged PR が見つからなければ保護 (未push branch や WIP を守る)
      merged=$(cd "$repo_root" && gh pr list --state merged --head "$branch" --json number --limit 1)
      if [ -z "$merged" ] || [ "$merged" = "[]" ]; then
        continue
      fi
      (
        cd "$wt" || exit 0
        for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
          if [ -f "$f" ]; then
            docker compose down -v --remove-orphans 2>/dev/null
            break
          fi
        done
      )
      git -C "$repo_root" worktree remove --force "$wt"
      git -C "$repo_root" branch -D "$branch" 2>/dev/null
    done
exit 0
