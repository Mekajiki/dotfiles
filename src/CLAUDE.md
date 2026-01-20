- Commit title message always should be what's is achieved by the change, not what the change is. Describe why you make the change below the title only when the change might be hard to understand.
- コミットは常に許可を求めろや

## PR作成

ユーザーがPR作成を依頼したら：

1. プラン中のユーザー発言をすべて `.git/claude-pr-context.txt` に書き出す
2. ユーザーに `gpr-claude` コマンドの実行を促す

書式：
- 見出しは `# 🗣️ Plan中に与えたプロンプト`
- 各発言の先頭に `💬` を付ける
- 発言間は `---` で区切る

```bash
# ユーザー発言の書き出し例
cat > "$(git rev-parse --show-toplevel)/.git/claude-pr-context.txt" << 'EOF'
# 🗣️ Plan中に与えたプロンプト

💬 ユーザーの発言1

---

💬 ユーザーの発言2
EOF
```

gpr-claudeスクリプトは `~/.local/bin/gpr-claude` に配置されている。