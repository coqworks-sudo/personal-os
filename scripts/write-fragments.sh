#!/bin/bash
# write-fragments.sh — Slack投稿をMarkdownファイルとして書き出し
#
# 使い方:
#   ./write-fragments.sh <messages_file> [date]

set -euo pipefail

export GEMINI_CLI_TRUST_WORKSPACE=true

MESSAGES_FILE="${1:?メッセージファイルのパスを指定してください}"
DATE="${2:-$(date +%Y-%m-%d)}"
REPO="$HOME/Claude-Workspace/personal-os"
FRAGMENTS_DIR="$HOME/Claude-Workspace/research/fragments"
QUEUE_DIR="$HOME/Claude-Workspace/research/queue"
LOG="$REPO/routine-detail.log"

echo "" >> "$LOG"
echo "===== [fragments] $DATE $(date '+%H:%M') =====" >> "$LOG"

MESSAGES=$(cat "$MESSAGES_FILE" 2>/dev/null || echo "")

# セクション抽出関数
extract_section() {
  local label="$1"
  echo "$MESSAGES" | awk "/=== ${label}/{found=1; next} found && /=== /{found=0} found{print}"
}

# --- #discoveries → research/fragments/ ---
DISCOVERIES=$(extract_section "#discoveries")

if [ -n "$DISCOVERIES" ] && ! echo "$DISCOVERIES" | grep -q "（新着なし）"; then
  echo "[fragments] #discoveries 処理中..." >> "$LOG"

  SLUG=$(echo "$DISCOVERIES" | gemini -p \
    "以下の投稿内容から3単語以内の英語スラッグを生成してください。ハイフン区切り・小文字のみ・単語のみ出力。" \
    --output-format text --approval-mode plan 2>/dev/null | tr -d '\n ' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
  SLUG="${SLUG:-untitled}"

  OUTFILE="$FRAGMENTS_DIR/${DATE}_${SLUG}.md"

  echo "$DISCOVERIES" | gemini -p \
    "以下のSlack投稿を整形し、Markdownファイルとして出力してください。前置きや説明文は不要です。以下の形式のみ出力してください:

---
source: slack/#discoveries
date: ${DATE}
tags: [適切なタグ]
summary: 一行要約
---

（本文：投稿の要点・洞察を箇条書きで整理）" \
    --output-format text --approval-mode plan 2>/dev/null > "$OUTFILE"

  echo "[fragments] 作成: $OUTFILE" >> "$LOG"
else
  echo "[fragments] #discoveries 新着なし" >> "$LOG"
fi

# --- #research-queue → research/queue/ ---
QUEUE=$(extract_section "#research-queue")

if [ -n "$QUEUE" ] && ! echo "$QUEUE" | grep -q "（新着なし）"; then
  echo "[fragments] #research-queue 処理中..." >> "$LOG"

  SLUG=$(echo "$QUEUE" | gemini -p \
    "以下の投稿内容から3単語以内の英語スラッグを生成してください。ハイフン区切り・小文字のみ・単語のみ出力。" \
    --output-format text --approval-mode plan 2>/dev/null | tr -d '\n ' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
  SLUG="${SLUG:-untitled}"

  OUTFILE="$QUEUE_DIR/${DATE}_${SLUG}.md"

  echo "$QUEUE" | gemini -p \
    "以下のSlack投稿を整形し、Markdownファイルとして出力してください。前置きや説明文は不要です。以下の形式のみ出力してください:

---
source: slack/#research-queue
date: ${DATE}
tags: [適切なタグ]
summary: 一行要約
---

（本文：調査依頼の要点・背景・優先度を箇条書きで整理）" \
    --output-format text --approval-mode plan 2>/dev/null > "$OUTFILE"

  echo "[fragments] 作成: $OUTFILE" >> "$LOG"
else
  echo "[fragments] #research-queue 新着なし" >> "$LOG"
fi

# --- rclone sync ---
if command -v rclone &>/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
  echo "[fragments] rclone sync 開始..." >> "$LOG"
  rclone sync "$FRAGMENTS_DIR" "gdrive:personal-os/fragments" --quiet 2>> "$LOG" && \
    echo "[fragments] rclone sync 完了" >> "$LOG" || \
    echo "[fragments] rclone sync 失敗（ログ確認）" >> "$LOG"
else
  echo "[fragments] rclone gdrive未設定 → スキップ" >> "$LOG"
fi

echo "[fragments] 完了"
