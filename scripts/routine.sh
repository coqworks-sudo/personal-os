#!/bin/bash
# personal-os daily routine script
#
# 使い方:
#   ./routine.sh <messages_file> [date]

set -euo pipefail

export GEMINI_CLI_TRUST_WORKSPACE=true

MESSAGES_FILE="${1:?メッセージファイルのパスを指定してください}"
DATE="${2:-$(date +%Y-%m-%d)}"
REPO="$HOME/Claude-Workspace/personal-os"
PROMPTS="$REPO/scripts/prompts"
LOG="$REPO/routine-detail.log"

# ログファイルに区切りを追加
echo "" >> "$LOG"
echo "===== $DATE $(date '+%H:%M') =====" >> "$LOG"

# メッセージの有無を判定
MESSAGES=$(cat "$MESSAGES_FILE" 2>/dev/null || echo "")
if echo "$MESSAGES" | grep -q "^\["; then
  HAS_MESSAGES=true
else
  HAS_MESSAGES=false
fi

# geminiが正しいディレクトリで動作するよう事前にcd
cd "$REPO"

# ---- ステップ1: テーマ更新 ----
echo "[Step 1] テーマ更新..." >> "$LOG"
gemini -p "$(cat "$PROMPTS/update-themes.txt")

$MESSAGES" \
  --output-format text \
  --yolo >> "$LOG" 2>&1

# 変更されたテーマファイルを検出
cd "$REPO"
THEME_CHANGES=$(git diff --name-only themes/ | sed 's|themes/||g' | sed 's|\.md||g' | tr '\n' ' ' | xargs)
if [ -z "$THEME_CHANGES" ]; then
  STEP1="変更なし"
else
  STEP1="$THEME_CHANGES 更新"
fi
echo "[Step 1] 完了: $STEP1" >> "$LOG"

# ---- ステップ2: synthesis更新 ----
echo "[Step 2] synthesis更新..." >> "$LOG"
gemini -p "$(cat "$PROMPTS/update-synthesis.txt")" \
  --output-format text \
  --yolo >> "$LOG" 2>&1

SYNTH_CHANGED=$(git diff --name-only synthesis/)
if [ -z "$SYNTH_CHANGED" ]; then
  STEP2="変更なし"
else
  STEP2="更新"
fi
echo "[Step 2] 完了: $STEP2" >> "$LOG"

# ---- ステップ3: 活動ログ生成・weekly更新 ----
echo "[Step 3] 活動ログ生成..." >> "$LOG"
gemini -p "$(cat "$PROMPTS/generate-log.txt" | sed "s|{DATE}|$DATE|g")

$DATE

$MESSAGES" \
  --output-format text \
  --yolo >> "$LOG" 2>&1

LOG_FILE="$REPO/todo/log/$DATE.md"
WEEKLY_CHANGED=$(git diff --name-only todo/weekly.md)
if [ -f "$LOG_FILE" ]; then
  if [ -n "$WEEKLY_CHANGED" ]; then
    STEP3="ログ作成 / weekly更新"
  else
    STEP3="ログ作成"
  fi
else
  STEP3="ログなし"
fi
echo "[Step 3] 完了: $STEP3" >> "$LOG"

# ---- ステップ4: git commit & push ----
git add .
if git diff --cached --quiet; then
  STEP4="変更なし"
else
  FILE_COUNT=$(git diff --cached --stat | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+')
  git commit -m "[routine] $DATE" >> "$LOG" 2>&1
  git push >> "$LOG" 2>&1
  STEP4="push済み（${FILE_COUNT}ファイル）"
fi
echo "[Step 4] 完了: $STEP4" >> "$LOG"

# ---- Slack向け出力 ----
if [ "$HAS_MESSAGES" = true ]; then
  echo "📅 $DATE ルーティン完了"
else
  echo "📅 $DATE ルーティン完了（収集なし）"
fi
echo ""
echo "🏷 テーマ: $STEP1"
echo "🔗 Synthesis: $STEP2"
echo "📝 ログ: $STEP3"
echo "📦 Git: $STEP4"
