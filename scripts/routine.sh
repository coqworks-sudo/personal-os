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
LOG_FILE="$REPO/todo/log/$DATE.md"

echo "" >> "$LOG"
echo "===== $DATE $(date '+%H:%M') =====" >> "$LOG"

MESSAGES=$(cat "$MESSAGES_FILE" 2>/dev/null || echo "")
if echo "$MESSAGES" | grep -q "^\["; then
  HAS_MESSAGES=true
else
  HAS_MESSAGES=false
fi

cd "$REPO"

# テーマファイルを連結して返す
read_themes() {
  for theme in ai-philosophy business-design personal-os tools-tech misc; do
    echo "=== themes/${theme}.md ==="
    cat "$REPO/themes/${theme}.md"
    echo ""
  done
}

# <<<FILE:name>>>...<<<ENDFILE>>> 形式を解析してファイルを書き出す
# context: "themes" | "synthesis" | "log"
parse_and_write() {
  local output="$1"
  local context="$2"
  echo "$output" | \
    REPO="$REPO" LOG_FILE="$LOG_FILE" CONTEXT="$context" python3 -c "
import sys, re, os

content = sys.stdin.read()
repo = os.environ['REPO']
log_file = os.environ['LOG_FILE']
ctx = os.environ['CONTEXT']

for fname, body in re.findall(r'<<<FILE:([^>]+)>>>\n(.*?)<<<ENDFILE>>>', content, re.DOTALL):
    body = body.rstrip('\n') + '\n'
    if fname == 'log':
        fpath = log_file
        os.makedirs(os.path.dirname(fpath), exist_ok=True)
    elif fname == 'weekly':
        fpath = os.path.join(repo, 'todo', 'weekly.md')
    elif ctx == 'synthesis':
        fpath = os.path.join(repo, 'synthesis', fname)
    else:
        fpath = os.path.join(repo, 'themes', fname)
    with open(fpath, 'w') as f:
        f.write(body)
    print('written: ' + fname, flush=True)
" 2>>"$LOG"
}

# ---- ステップ1: テーマ更新 ----
echo "[Step 1] テーマ更新..." >> "$LOG"

THEMES_CONTENT=$(read_themes)
SOUL_CONTENT=$(cat "$REPO/claude/SOUL.md")

STEP1_OUTPUT=$(gemini -p "$(cat "$PROMPTS/update-themes.txt")

## エージェントの姿勢と価値観（SOUL）
$SOUL_CONTENT

## 現在のテーマファイル
$THEMES_CONTENT

## 収集メッセージ
$MESSAGES" \
  --output-format text --approval-mode plan 2>>"$LOG")

echo "$STEP1_OUTPUT" >> "$LOG"
parse_and_write "$STEP1_OUTPUT" "themes"

THEME_CHANGES=$(git diff --name-only themes/ | sed 's|themes/||g' | sed 's|\.md||g' | tr '\n' ' ' | xargs 2>/dev/null || true)
if [ -z "$THEME_CHANGES" ]; then
  STEP1="変更なし"
else
  STEP1="$THEME_CHANGES 更新"
fi
echo "[Step 1] 完了: $STEP1" >> "$LOG"

# ---- ステップ2: synthesis更新 ----
echo "[Step 2] synthesis更新..." >> "$LOG"

THEMES_CONTENT=$(read_themes)
SYNTHESIS_CONTENT=$(cat "$REPO/synthesis/synthesis.md")

STEP2_OUTPUT=$(gemini -p "$(cat "$PROMPTS/update-synthesis.txt")

## 現在のテーマファイル
$THEMES_CONTENT

## 現在のsynthesis.md
$SYNTHESIS_CONTENT" \
  --output-format text --approval-mode plan 2>>"$LOG")

echo "$STEP2_OUTPUT" >> "$LOG"
parse_and_write "$STEP2_OUTPUT" "synthesis"

SYNTH_CHANGED=$(git diff --name-only synthesis/)
if [ -n "$SYNTH_CHANGED" ]; then STEP2="更新"; else STEP2="変更なし"; fi
echo "[Step 2] 完了: $STEP2" >> "$LOG"

# ---- ステップ3: 活動ログ生成・weekly更新 ----
echo "[Step 3] 活動ログ生成..." >> "$LOG"

WEEKLY_CONTENT=$(cat "$REPO/todo/weekly.md")

STEP3_OUTPUT=$(gemini -p "$(cat "$PROMPTS/generate-log.txt" | sed "s|{DATE}|$DATE|g")

## 現在のweekly.md
$WEEKLY_CONTENT

## 対象日付
$DATE

## 収集メッセージ
$MESSAGES" \
  --output-format text --approval-mode plan 2>>"$LOG")

echo "$STEP3_OUTPUT" >> "$LOG"
parse_and_write "$STEP3_OUTPUT" "log"

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
