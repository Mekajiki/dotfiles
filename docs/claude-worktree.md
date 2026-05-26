# Claude Code 並行作業（worktree）

同一リポジトリで複数の Claude Code セッションを並行させるための整備。Claude が会話の文脈から branch 名を決めて `EnterWorktree` で worktree を切り、続いて `cl-setup.sh` で host port と docker compose project 名を分離する。終了時の片付けもフックで自動化する。

## 何を解決するか

| 問題 | 対策 |
| --- | --- |
| 同じ作業ツリーで複数 Claude がファイル編集して衝突 | `EnterWorktree` で `.claude/worktrees/<branch>/` に物理分離 |
| 複数 worktree で同じ compose を立ち上げるとリソース名がぶつかる | `cl-setup.sh` が `compose.override.yml` を生成、トップレベル `name: <repo>-<branch>` で project 名を分離 |
| host port 衝突（複数 worktree で `3000:3000` を取り合う） | `cl-setup.sh` が branch 名 hash から決定的に host port を算出し override にリテラルで埋め込む |
| `down` 忘れ・volume 残骸の蓄積 | `SessionEnd` フックで `docker compose down -v --remove-orphans`（override は auto-load される） |
| merge 済み branch の worktree が残り続ける | `SessionStart` フックで「origin から消えた branch」の worktree を docker down + worktree remove |

## スコープ外

- 複数セッションの一覧・横断 UI → Claude Code デスクトップアプリ刷新で吸収
- `make up` / `make db/setup` の自動実行 → Claude に都度依頼
- Rails 側の URL hardcode（`config/puma.rb` の `port: 3000` 等）→ アプリ側の修正範囲
- dangling images / build cache の定期掃除 → launchd で別途 `docker system prune`
- anipos の service 名（`server`, `mailcatcher`, `yard`, `chrome`）と異なる compose を持つリポの port 分離
- リポに `compose.override.yml` が commit されているケース（dotfiles は無条件で上書きする）

## 想定フロー

```
1. terminal でリポルートに移動し claude を起動
2. ユーザー「XXX を実装して」と指示
3. Claude:
   a. EnterWorktree('feature-xxx')
      → .claude/worktrees/feature-xxx/ 作成、セッションがそこへ移動
   b. bash ~/.claude/hooks/cl-setup.sh
      → cwd の basename (= feature-xxx) を branch 名として認識
      → base compose を検出し、その中に存在する anipos service だけ override 対象に
      → branch 名 hash から host port を計算
      → compose.override.yml (auto-load 名) を worktree 直下に生成
        (リテラル port 値, name: <repo>-feature-xxx)
4. Claude が make up / docker compose up -d を叩く
   → auto-load された override により port と project 名が分離された状態で起動
5. /exit
   → SessionEnd フック: docker compose down -v --remove-orphans
6. 別のセッションを起動 (どこかのリポルートで)
   → SessionStart フック: 当該リポの .claude/worktrees/ 配下を走査、
     「origin にもう存在しない branch」の worktree を docker down + worktree remove + branch -D
```

Claude へ「EnterWorktree 直後に cl-setup.sh を呼ぶ」ルールはグローバル `~/.claude/CLAUDE.md`（dotfiles の `src/CLAUDE.md`）に記述してある。

## `cl-setup.sh` の動作

### 呼び出し方

```sh
bash ~/.claude/hooks/cl-setup.sh
```

引数なし。cwd が `.claude/worktrees/<branch>/` であることを前提とする。

### やること

1. cwd の basename を `<branch>` として認識
2. `git rev-parse --git-common-dir` で main worktree の repo root を辿り、basename を `<repo>` として認識
3. `<branch>` の sha1 hash から host port を計算
   - server: `20000 + (hash % 1000)`
   - mailcatcher: `21000 + (hash % 1000)`
   - yard: `22000 + (hash % 1000)`
   - chrome (VNC): `23000 + (hash % 1000)`
4. base compose を検出（`compose.yml` → `compose.yaml` → `docker-compose.yml` → `docker-compose.yaml` の優先順）
5. `docker compose -f <base> config --services` で base に存在する service 一覧を取得
6. anipos の 4 service（server / mailcatcher / yard / chrome）のうち base に存在するもののみ override を出力:
   ```yaml
   name: <repo>-<branch>
   services:
     server:
       ports: !override
         - "<server_port>:3000"
     # mailcatcher は monorail 等で省略される
     yard:
       ports: !override
         - "<yard_port>:8808"
     chrome:
       ports: !override
         - "<chrome_vnc_port>:5900"
   ```
7. 出力先は base に対応する auto-load 名（`compose.yml` → `compose.override.yml` 等）
8. port 一覧を stdout に表示
9. compose ファイルが無いリポでは何も生成せず exit 0

### auto-load について

compose v2 は base と同じ場所にある `<base>.override.<ext>` を自動で読み込む。
このため `make up` / 素の `docker compose up` / `docker compose down` のどれを叩いても override が反映される。`-f` を明示する必要はない。

### anipos service 名と合致しないリポでの挙動

- service 検出により、base に無い service は override に出力されない
- すべての anipos service が無いリポでも override は生成される（`services:` 配下が空）
- 一切影響を出したくない場合は `cl-setup.sh` を呼ばない（CLAUDE.md の指示を例外として無視）

### 既存の `compose.override.yml` を上書きする件

リポに `compose.override.yml` が commit されている運用は anipos では想定外。`cl-setup.sh` は無条件で上書きする。

## hooks

### `SessionStart` ─ `~/.claude/hooks/worktree-cleanup.sh`

Claude セッション開始時に発火。cwd が git リポなら:

1. `git fetch --prune origin`（失敗してもスキップ）
2. `.claude/worktrees/` 配下の worktree を列挙
3. 各 worktree について、`git ls-remote --heads origin <branch>` でヒットしなければ:
   - 当該 worktree に base compose があれば `docker compose down -v --remove-orphans`（override は auto-load）
   - `git worktree remove --force <wt>`
   - `git branch -D <branch>`

GitHub の "Automatically delete head branches" 設定が ON の前提（PR マージで origin から branch が消える）。

### `SessionEnd` ─ `~/.claude/hooks/worktree-session-end.sh`

Claude セッション終了時に発火。cwd が `.claude/worktrees/` 配下で base compose があれば `docker compose down -v --remove-orphans` を実行（override は auto-load）。

## セットアップ

### 新規導入

`install.sh` 経由（`link_files.sh` が `src/claude-hooks/*.sh` を `~/.claude/hooks/` に symlink する）。
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

`./link_files.sh` を再実行すれば `~/.claude/hooks/` の symlink (cl-setup, worktree-cleanup, worktree-session-end) は最新に更新される。

## トラブルシュート

### port が衝突したと言われる

branch 名の hash 由来なので確率は低いが 0 ではない。違う branch 名にリネームして再度 `cl-setup.sh` を呼ぶと回避できる。

### 自動掃除で消したくない worktree が消えた

`SessionStart` フックの判定は「origin に branch が無い」のみ。ローカルで作って push してない作業中 branch は対象になる。push してから次の claude を起動するか、フックを一時的に無効化（`~/.claude/settings.json` の `SessionStart` を一時削除）。

### compose `!override` syntax が効かない

Docker Compose v2 系で動作確認済み。古い `docker-compose` (v1) では未対応。`docker compose version` で v2 系か確認。
