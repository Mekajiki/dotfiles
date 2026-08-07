---
name: slack
description: >-
  Slack のメッセージ・スレッド・チャネルを読む/調べる/投稿するときに使う（「Slackで確認して」
  「このスレッド読んで」「#channel に投稿して」，Slack permalink の貼り付け等）．
  workspace ごとの bot token の在り処は ~/.claude/slack-workspaces.md（ローカル管理・非コミット）に持つ．
  どのリポジトリで作業中でも使える．
---

# Slack アクセス

## workspace と token

環境固有の情報（workspace ごとの token の置き場・投稿スクリプト・Slack App 名・チャネルID の在り処等）は **`~/.claude/slack-workspaces.md`** に置いてある（このリポは公開のためコミットしない）．まずそのファイルを Read し，作業中のリポや指示の文脈から workspace を決める．ファイルが無い・該当 workspace が無い場合はユーザーに確認する．新しい workspace の追加は bot app 作成・チャネル invite・token 保存が別途必要なので，相談の上ファイルに追記する．

token は同一コマンド内で source して環境変数で使う（Bash ツールは呼び出しごとに別シェルなので分割しない．`$()` は使わない）：

```bash
source <token定義ファイル> && curl -s ...
```

## 読み取り（Web API）

```bash
# チャネル履歴
curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C0XXXXXXXXX&limit=50"
# スレッド（ts は親メッセージの ts）
curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=C0XXXXXXXXX&ts=1234567890.123456"
# ユーザー名解決
curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  "https://slack.com/api/users.info?user=U0XXXXXXXXX"
```

- permalink `https://<ws>.slack.com/archives/<channel>/p1234567890123456` は channel と ts（`1234567890.123456` 形式に変換）に分解して `conversations.replies` を叩く．query に `thread_ts=` があればそちらが親の ts．
- チャネルIDは指示・permalink・workspace ファイル記載の在り処から得る．不明なら `conversations.list` を試し，スコープ不足ならユーザーに聞く．
- bot は参加しているチャネルしか読めない．`not_in_channel` が返ったら invite を依頼する（public チャネルなら `conversations.join` も可）．
- `search.messages` は user token 専用で bot token では使えない．検索が必要な場合はチャネルを特定して history を絞り込む．

## 投稿

投稿手段（スクリプト・チャネルIDの管理方法）は `~/.claude/slack-workspaces.md` の当該 workspace の記載に従う．投稿は外向き操作なので，事前に宛先と本文を提示して確認を取る．

## missing_scope が出たら

bot へのスコープ追加と reinstall はユーザー操作が必要なので，必要なスコープ名を添えて依頼する（App の管理場所は workspace ファイル参照）．
