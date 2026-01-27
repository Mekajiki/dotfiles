- Commit title message always should be what's is achieved by the change, not what the change is. Describe why you make the change below the title only when the change might be hard to understand.
- コミットは常に許可を求めろや

## PR作成

### プランモード中のユーザー発言の記録

プランモード中、ユーザーが発言するたびに `.git/claude-pr-context.txt` へ追記する。

- 最初の発言時にファイルを作成し、見出し `# 🗣️ Plan中に与えたプロンプト` を書く
- 各発言の先頭に `💬` を付ける
- 発言間は `---` で区切る

```bash
# 初回
cat > "$(git rev-parse --show-toplevel)/.git/claude-pr-context.txt" << 'EOF'
# 🗣️ Plan中に与えたプロンプト

💬 ユーザーの発言1
EOF

# 2回目以降（追記）
cat >> "$(git rev-parse --show-toplevel)/.git/claude-pr-context.txt" << 'EOF'

---

💬 ユーザーの発言2
EOF
```

### PR作成時

ユーザーがPR作成を依頼したら、`.git/claude-pr-context.txt` が存在する前提で進める。