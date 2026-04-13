#!/bin/bash
# personal-os daily routine script
# n8nのExecute CommandノードからSlackメッセージを受け取って実行する
#
# 使い方:
#   ./routine.sh <messages_file> [date]
#
# 引数:
#   messages_file : Slackメッセージが書き込まれたテキストファイルのパス
#   date          : 対象日付 YYYY-MM-DD（省略時は今日）
#
# メッセージファイルのフォーマット（n8nのCodeノードで生成）:
#   === #discoveries (YYYY-MM-DD) ===
#   [HH:MM] username: message text
#   ...
#   === #research-queue (YYYY-MM-DD) ===
#   [HH:MM] username: message text
#   ...

set -euo pipefail

MESSAGES_FILE="${1:?メッセージファイルのパスを指定してください}"
DATE="${2:-$(date +%Y-%m-%d)}"
REPO="$HOME/Claude-Workspace/personal-os"
PROMPTS="$REPO/scripts/prompts"

echo "[routine] ===== 開始: $DATE ====="

# ---- ステップ1: テーマ更新 ----
echo "[routine] Step 1: テーマ更新..."
MESSAGES=$(cat "$MESSAGES_FILE" 2>/dev/null || echo "（メッセージなし）")
claude -p "$(cat "$PROMPTS/update-themes.txt")

$MESSAGES" \
  --allowedTools "Read,Edit,Glob,Grep" \
  --output-format text
echo "[routine] Step 1: 完了"

# ---- ステップ2: synthesis更新 ----
echo "[routine] Step 2: synthesis更新..."
claude -p "$(cat "$PROMPTS/update-synthesis.txt")" \
  --allowedTools "Read,Edit,Glob,Grep" \
  --output-format text
echo "[routine] Step 2: 完了"

# ---- ステップ3: 活動ログ生成・weekly更新 ----
echo "[routine] Step 3: 活動ログ生成..."
claude -p "$(cat "$PROMPTS/generate-log.txt" | sed "s|{DATE}|$DATE|g")

$DATE

$MESSAGES" \
  --allowedTools "Read,Write,Edit,Glob" \
  --output-format text
echo "[routine] Step 3: 完了"

# ---- ステップ4: git commit & push ----
echo "[routine] Step 4: git push..."
cd "$REPO"
git add .
if git diff --cached --quiet; then
  echo "[routine] 変更なし、コミットスキップ"
else
  git commit -m "[routine] $DATE"
  git push
  echo "[routine] Step 4: push完了"
fi

echo "[routine] ===== 終了: $DATE ====="
