#!/bin/bash
# push-to-drive.sh — research/fragments を Google Drive に同期
#
# 前提: rclone config で "gdrive" リモートを設定済みであること
#   rclone config → Google Drive → remote name: gdrive
#
# 使い方:
#   ./push-to-drive.sh           # 通常同期
#   ./push-to-drive.sh --dry-run # ドライラン（実際には同期しない）

set -euo pipefail

REPO="$HOME/Claude-Workspace/personal-os"
LOCAL_DIR="$HOME/Claude-Workspace/research/fragments"
REMOTE_DIR="gdrive:personal-os/fragments"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="--dry-run"
  echo "[push-to-drive] ドライランモード（実際には同期しません）"
fi

echo "[push-to-drive] 同期開始: $LOCAL_DIR → $REMOTE_DIR"

rclone sync "$LOCAL_DIR" "$REMOTE_DIR" \
  --progress \
  --exclude "*.tmp" \
  $DRY_RUN

echo "[push-to-drive] 完了"
