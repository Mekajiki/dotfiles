# Claude Code 並行作業（worktree）

同一リポジトリで複数の Claude Code セッションを並行させるための整備。Claude が会話の文脈から branch 名を決めて `EnterWorktree` で worktree を切り、続いて `cl-setup.sh` で host port と docker compose project 名を分離する。終了時の片付けもフックで自動化する。

## 何を解決するか

| 問題 | 対策 |
| --- | --- |
| 同じ作業ツリーで複数 Claude がファイル編集して衝突 | `EnterWorktree` で `.claude/worktrees/<branch>/` に物理分離 |
| 複数 worktree で同じ compose を立ち上げるとリソース名がぶつかる | `cl-setup.sh` が `compose.override.yml` を生成、トップレベル `name: <repo>-<branch>` で project 名を分離 |
| host port 衝突（複数 worktree で `3000:3000` を取り合う） | `cl-setup.sh` が branch 名 hash から決定的に host port を算出し override にリテラルで埋め込む |
| project 分離により volume も空になり、worktree ごとに `bundle install` / `yarn install` を待たされる | `cl-setup.sh` が main worktree の install 系 volume（bundler / yarn / node_modules）を複製 |
| `down` 忘れ・volume 残骸の蓄積 | `SessionEnd` フックで `docker compose down -v --remove-orphans`（override は auto-load される） |
| merge 済み branch の worktree が残り続ける | `SessionStart` フックで「origin から消えた branch」の worktree を docker down + worktree remove |

## スコープ外

- 複数セッションの一覧・横断 UI → Claude Code デスクトップアプリ刷新で吸収
- `make up` / `make db/setup` の自動実行 → Claude に都度依頼
- Rails 側の URL hardcode（`config/puma.rb` の `port: 3000` 等）→ アプリ側の修正範囲
- dangling images / build cache の定期掃除 → launchd で別途 `docker system prune`
- anipos の service 名（`server`, `mailcatcher`, `yard`, `chrome`）と異なる compose を持つリポの port 分離
- リポに `compose.override.yml` が commit されているケース（dotfiles は無条件で上書きする）
- DB データの引き継ぎ（`pg_volume` の複製）→ 稼働中の data directory を生コピーすると壊れた断面になり得るので複製しない。`make db/setup` で作る

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
      → main worktree の install 系 volume を新 project 名の volume に複製
4. Claude が make up / docker compose up -d を叩く
   → auto-load された override により port と project 名が分離された状態で起動
5. /exit
   → SessionEnd フック: docker compose down -v --remove-orphans
6. 別のセッションを起動 (どこかのリポルートで)
   → SessionStart フック: 当該リポの .claude/worktrees/ 配下を走査、
     「origin にもう存在しない branch」の worktree を docker down + worktree remove + branch -D
```

Claude へのルール（「ファイル編集 or サーバ立ち上げが必要になったら `EnterWorktree` で worktree を切る」「`EnterWorktree` 直後に `cl-setup.sh` を呼ぶ」）はグローバル `~/.claude/CLAUDE.md`（dotfiles の `src/CLAUDE.md`）に記述してある。

## `cl-setup.sh` の動作

### 呼び出し方

```sh
bash ~/.claude/hooks/cl-setup.sh
```

引数なし。cwd が `.claude/worktrees/<branch>/` であることを前提とする。

### やること

1. cwd の basename を `<branch>` として認識
2. `git rev-parse --git-common-dir` で main worktree の repo root を辿り、basename を `<repo>` として認識
3. project 名を `<repo>-<branch>` から compose と同じ規則（小文字化 + `[a-z0-9_-]` 以外を除去）で正規化
4. `<branch>` の sha1 hash から host port を計算
   - server: `20000 + (hash % 1000)`
   - mailcatcher: `21000 + (hash % 1000)`
   - yard: `22000 + (hash % 1000)`
   - chrome (VNC): `23000 + (hash % 1000)`
5. base compose を検出（`compose.yml` → `compose.yaml` → `docker-compose.yml` → `docker-compose.yaml` の優先順）
6. `docker compose -f <base> config --services` で base に存在する service 一覧を取得
7. anipos の 4 service（server / mailcatcher / yard / chrome）のうち base に存在するもののみ override を出力:
   ```yaml
   name: <project>
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
8. 出力先は base に対応する auto-load 名（`compose.yml` → `compose.override.yml` 等）
9. port 一覧を stdout に表示
10. install 系 volume を main worktree から複製（後述）
11. compose ファイルが無いリポでは何も生成せず exit 0

### volume の複製

project 名を分けた副作用として volume も新規＝空になり、worktree ごとに `bundle install` / `yarn install` をやり直すことになる。これを避けるため、main worktree の volume が既にあれば中身を複製してから起動する。

- 対象は install 成果物・キャッシュだけ（`bundler_volume` / `yarn_volume` / `node_modules_volume`）。リポの compose に定義が無いものは黙って skip する
- `pg_volume` 等のデータ volume は複製しない（スコープ外を参照）
- 複製元は `<main の project 名>_<volume 名>`。main の project 名は `docker compose config` の `name:` 行から取り、取れなければ repo 名を正規化して組み立てる
- 複製先が既にあって中身が入っていれば何もしない（冪等）
- 複製は `busybox cp -a` を挟んだ一時コンテナで行う。monorail の3つ（計 1.6GB 程度）で約10秒
- 複製に失敗したら複製先 volume を消して先に進む（install からやり直しになるだけ）

monorail で計測した効果:

| | 空 volume から | main から複製 |
| --- | --- | --- |
| `bundle install` | 42.4s | 0.8s |
| `yarn install` | 11.5s | 4.1s |

複製元が古いと差分だけ install が走る。特に main の image の ruby が worktree の image と違うと native extension が全部作り直しになり、`bundle install` が 33.7s まで戻る（それでも空からより速い）。トラブルシュートを参照。

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
2. `.claude/worktrees/` 配下の worktree を列挙（branch 名は `git worktree list --porcelain` の `branch refs/heads/<name>` から取得。Claude `EnterWorktree` は dir basename と異なる `worktree-<name>` を作るため）
3. 各 worktree について、以下を**両方**満たした場合だけ掃除する:
   - **条件A**: `git ls-remote --heads origin <branch>` でヒットしない（origin に branch が存在しない）
   - **条件B**: `gh pr list --state merged --head <branch>` で merged PR が見つかる（squash merge 対応）

掃除内容:
- 当該 worktree に base compose があれば `docker compose down -v --remove-orphans`（override は auto-load）
- `git worktree remove --force <wt>`
- `git branch -D <branch>`

GitHub の "Automatically delete head branches" 設定が ON の前提。条件 B により未push の WIP branch（PR が無い）は保護される。`gh` CLI が無い／タイムアウト等の場合は条件 B が空判定になり保護側に倒れる。

### `SessionEnd` ─ `~/.claude/hooks/worktree-session-end.sh`

Claude セッション終了時に発火。cwd が `.claude/worktrees/` 配下で base compose があれば `docker compose down -v --remove-orphans` を実行（override は auto-load）。

## セットアップ

`install.sh` または `./link_files.sh` を実行すれば自動で全部入る:

- `src/claude-hooks/*.sh` → `~/.claude/hooks/` に個別 symlink
- `src/claude-settings.local.json` → `~/.claude/settings.local.json` に symlink

hooks を含む dotfiles 管理の設定はすべて `claude-settings.local.json` に書いてある。Claude 本体は `settings.local.json` には書き込まないので symlink で安全。`settings.json` と Claude Code 側でマージされ、scalar (theme 等) は settings.local が優先、array (hooks, permissions.allow) は連結+重複排除、object は deep merge される。

新規/既存ユーザー区別なく、`./link_files.sh` を再実行するだけで設定の追加・更新が反映される。手動マージ作業は不要。なお `/config` UI で theme 等の scalar を変えても settings.json に書かれ settings.local が勝つので実質無視される（変更は dotfiles を編集）。

## トラブルシュート

### port が衝突したと言われる

branch 名の hash 由来なので確率は低いが 0 ではない。違う branch 名にリネームして再度 `cl-setup.sh` を呼ぶと回避できる。

### 自動掃除で消えない worktree がある

`SessionStart` フックは「origin に無い AND merged PR がある」を両方満たすときだけ削除する。以下のケースは保護される（=残る）:
- 未push の WIP branch（PR が無いので merged PR ヒットせず）
- まだ open な PR の branch（merged PR が空配列）
- squash merge ではなく force-push リセット等で別履歴になった branch
- `gh` がタイムアウトや認証エラーで失敗したケース

不要なら手動で `git -C <repo> worktree remove --force <wt> && git -C <repo> branch -D <branch>` を叩く。

### volume を複製したのに `bundle install` が走る

worktree は project ごとに image を build するので、main が古い image のまま（`make build` していない）だと ruby の版が食い違う。extension は `extensions/<platform>/<ruby api version>/` 配下に置かれるため、版が違うと native extension を持つ gem が全部作り直しになる。

```sh
docker run --rm --entrypoint ruby <repo>-bundler:latest -e 'puts RUBY_VERSION'
docker run --rm --entrypoint ruby <repo>-<branch>-bundler:latest -e 'puts RUBY_VERSION'
```

食い違っていたら main 側で `make build && make up` して複製元を作り直す。

### compose `!override` syntax が効かない

Docker Compose v2 系で動作確認済み。古い `docker-compose` (v1) では未対応。`docker compose version` で v2 系か確認。
