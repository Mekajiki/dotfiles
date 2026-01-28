- Commit title message always should be what's is achieved by the change, not what the change is. Describe why you make the change below the title only when the change might be hard to understand.
- コミットは常に許可を求めろや

## ユーザー発言の記録

プランモード・実装モード問わず、ユーザーが発言するたびに `.git/claude-pr-context.txt` へ追記する。

- 最初の発言時にファイルを作成し、見出し `# 🗣️ Claudeに与えたプロンプト` を書く
- 各発言の先頭に `💬` を付ける
- 発言間は `---` で区切る

```bash
# 初回
printf '# 🗣️ Claudeに与えたプロンプト\n\n💬 ユーザーの発言1\n' > "$(git rev-parse --show-toplevel)/.git/claude-pr-context.txt"

# 2回目以降（追記）
printf '\n---\n\n💬 ユーザーの発言2\n' >> "$(git rev-parse --show-toplevel)/.git/claude-pr-context.txt"
```
