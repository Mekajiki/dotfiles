# Claude Code 並行作業（worktree）

同一リポジトリで複数の Claude Code セッションを並行させるための整備。`cl` コマンド一発で git worktree を切って Claude を起動し、終了時に docker compose の片付けを自動化する。

## 何を解決するか

| 問題 | 対策 |
| --- | --- |
| 同じ作業ツリーで複数 Claude がファイル編集して衝突 | `cl` が worktree を `.claude/worktrees/<branch>/` に切って物理分離 |
| 同じ compose で起動するとリソース名がぶつかる | worktree ごとに `COMPOSE_PROJECT_NAME=<repo>-<branch>` を export |
| host port 衝突（複数 worktree で `3000:3000` を取り合う） | `compose.worktree.yml` を自動生成、branch hash から計算した host port を `${SERVER_PORT}` 等で上書き |
| `down` 忘れ・volume 残骸の蓄積 | `SessionEnd` フックで `docker compose down -v --remove-orphans` |
| merge 済み branch の worktree が残り続ける | `SessionStart` フックで「origin から消えた branch」の worktree を docker down + remove |

## スコープ外

- 複数セッションの一覧・横断 UI → Claude Code デスクトップアプリ刷新で吸収
- `make up` / `make db/setup` の自動実行 → Claude に都度依頼
- Rails 側の URL hardcode（`config/puma.rb` の `port: 3000` 等）→ アプリ側の修正範囲
- dangling images / build cache の定期掃除 → launchd で別途 `docker system prune`
- anipos の service 名（`server`, `pg`, `mailcatcher`, `yard`, `chrome`）と異なる compose を持つリポの port 分離

## `cl` コマンド spec

### 使い方

```sh
cl <branch>
```

リポルート（`.git` を含むディレクトリ）で実行する。

### 動作

1. `.claude/worktrees/<branch>/` に git worktree を切る（既に存在すれば再利用）
2. その worktree に `cd`
3. 以下を export
   - `COMPOSE_PROJECT_NAME=<repo>-<branch>`
   - `SERVER_PORT` / `MAILCATCHER_PORT` / `YARD_PORT` / `CHROME_VNC_PORT`（branch 名の sha1 hash から 20000-29999 で算出、決定的）
4. `compose.yml` / `compose.yaml` / `docker-compose.yml` / `docker-compose.yaml` のいずれかがあれば
   - `compose.worktree.yml` をその worktree に生成
   - `COMPOSE_FILE=<base>:compose.worktree.yml` を export
5. `claude` を起動

### `compose.worktree.yml` の中身

```yaml
services:
  server:
    ports: !override
      - "${SERVER_PORT}:3000"
  mailcatcher:
    ports: !override
      - "${MAILCATCHER_PORT}:1080"
  yard:
    ports: !override
      - "${YARD_PORT}:8808"
  chrome:
    ports: !override
      - "${CHROME_VNC_PORT}:5900"
```

`!override` で base compose の `ports` を完全置換する（compose v2 syntax）。

### anipos service 名と合致しないリポでの挙動

- worktree 作成、`cd`、`COMPOSE_PROJECT_NAME` export までは同じく動く
- `compose.worktree.yml` も生成されるが、`COMPOSE_FILE` で読み込んだ時に「base に存在しない service」のエラーになる
- → cl session 内では `docker compose` 系のコマンドが失敗する。対処は以下のいずれか:
  - 手動で `unset COMPOSE_FILE` して docker を使う
  - `compose.worktree.yml` を編集して、自リポの service 名に書き換える（個人運用、`.gitignore` 推奨）

## hooks

### `SessionStart` ─ `~/.claude/hooks/worktree-cleanup.sh`

Claude セッション開始時に発火。cwd が git リポなら:

1. `git fetch --prune origin`（失敗してもスキップ）
2. `.claude/worktrees/` 配下の worktree を列挙
3. 各 worktree について、`git ls-remote --heads origin <branch>` でヒットしなければ:
   - `docker compose down -v --remove-orphans`（COMPOSE_PROJECT_NAME 復元のうえ）
   - `git worktree remove --force <wt>`
   - `git branch -D <branch>`

GitHub の "Automatically delete head branches" 設定が ON の前提（PR マージで origin から branch が消えるパターン）。

### `SessionEnd` ─ `~/.claude/hooks/worktree-session-end.sh`

Claude セッション終了時に発火。cwd が `.claude/worktrees/` 配下で、`compose.yml` 系がある場合のみ `docker compose down -v --remove-orphans` を実行。

## セットアップ

### 新規導入

`install.sh` 経由（`link_files.sh` が `~/.claude/hooks/` にスクリプトを symlink する）。
新規ユーザーは `src/claude-settings.json.example` がそのまま `~/.claude/settings.json` にコピーされるので、hooks 設定も自動で入る。

### 既存ユーザー（既に `~/.claude/settings.json` がある場合）

`~/.claude/settings.json` は Claude が随時書き換えるため symlink できない。
以下を手動で `~/.claude/settings.json` のトップレベルにマージ:

```json
"hooks": {
  "SessionStart": [
    {
      "hooks": [
        { "type": "command", "command": "${HOME}/.claude/hooks/worktree-cleanup.sh" }
      ]
    }
  ],
  "SessionEnd": [
    {
      "hooks": [
        { "type": "command", "command": "${HOME}/.claude/hooks/worktree-session-end.sh" }
      ]
    }
  ]
}
```

`./link_files.sh` を再実行すれば `~/.claude/hooks/` の symlink は更新される。

## トラブルシュート

### `cl` 起動後、`docker compose up` で `service ... has neither image nor build context`

base compose に anipos 想定の service 名（`server` 等）が無いリポ。`unset COMPOSE_FILE` で base のみ使うか、`compose.worktree.yml` を編集する。

### port が衝突したと言われる

branch 名の hash 由来なので確率は低いが 0 ではない。違う branch 名にリネームすれば回避。

### 自動掃除で消したくない worktree が消えた

`SessionStart` フックの判定は「origin に branch が無い」のみ。ローカルで作って push してない作業中 branch は対象になる。push してから `cl` 起動するか、フックを一時的に無効化（`~/.claude/settings.json` の `SessionStart` を一時削除）。

### compose `!override` syntax が効かない

Docker Compose v2 系統で動作確認済み。古い `docker-compose` (v1) では未対応。`docker compose version` で v2 系か確認。
