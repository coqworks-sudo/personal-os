# HARNESS — n8nルーティン仕様

## ワークフロー概要

**実行タイミング：毎朝定刻（時刻はn8n側で設定）**

### ステップ1: 歯車収集
- #discoveries（ID: C0ARKPXRPU6）の新着メッセージを取得
- #research-queue（ID: C0ARJ9PJVD3）の新着メッセージを取得
- 前回実行タイムスタンプ以降のみ対象

### ステップ2: テーマ分類・統合
- Claude APIを呼び出してthemes/各ファイルを更新
- 変更がなければスキップ

### ステップ3: テーマ横断分析
- synthesis/synthesis.mdを更新

### ステップ4: 活動ログ生成
- #discoveries + #research-queueから前日の活動を収集
- todo/log/YYYY-MM-DD.md を生成
- weekly.mdの進捗を更新

### ステップ5: GitHubにpush
- コミットメッセージ: `[routine] YYYY-MM-DD`

### ステップ6: #dailyに通知
- チャンネルID: C0AT6CBAJ1W
- 通知内容:
  - 今週のTODO残タスク数
  - 前日の活動まとめ（3行以内）
  - 追跡なしの場合: 「昨日の記録が見当たりませんでした。何か進みましたか？」

## APIキー・認証情報
- Slack Bot Token: n8n環境変数から取得
- Claude API Key: n8n環境変数から取得
- GitHub Token: n8n環境変数から取得

## コミット規約
| prefix | 意味 |
|---|---|
| [routine] | n8n自動処理 |
| [human+claude] | 対話を経た更新 |
| [human] | ひとりでの直接編集 |
