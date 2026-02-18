- Commit title message always should be what's is achieved by the change, not what the change is. Describe why you make the change below the title only when the change might be hard to understand.
- コミットは常に許可を求めろや

# プランのファイルへの記録
## ユーザー発言の記録

プランモード・実装モード問わず、ユーザーが発言するたびに `claude-pr-context.txt` へ追記する。

- `claude-pr-context.txt` が存在しないか空なら、見出し付きで新規作成する
- 既に内容があれば `---` 区切りで追記する
- 各発言の先頭に `💬` を付ける

```bash
# ファイルが存在しないか空なら初回扱い
if [ ! -s claude-pr-context.txt ]; then
  printf '# 🗣️ Claudeに与えたプロンプト\n\n💬 ユーザーの発言\n' > claude-pr-context.txt
else
  printf '\n---\n\n💬 ユーザーの発言\n' >> claude-pr-context.txt
fi
```

## プランファイルの記録
プランモードを抜けたタイミングで，claude-pr-context.txtにプランファイルのセクションを設け，プランを追記する．
