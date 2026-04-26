# HARNESS — n8nルーティン仕様

_最終更新：2026-04-26（Gemini移行後の実態に合わせて更新）_

## ワークフロー概要

**実行タイミング：毎朝定刻（時刻はn8n側で設定）**

### ステップ1: Slackメッセージ収集（n8n）
- #discoveries（ID: C0ARKPXRPU6）の新着メッセージを取得
- #research-queue（ID: C0ARJ9PJVD3）の新着メッセージを取得
- #daily（ID: C0AT6CBAJ1W）の新着メッセージを取得
- 前回実行タイムスタンプ以降のみ対象
- 収集結果を `/tmp/personal-os-messages.txt` に書き出す

### ステップ2: routine.sh 実行（n8n → HTTP Request → routine-server.py）
- `routine-server.py`（ポート5680）がroutine.shをsubprocessで起動
- `scripts/routine.sh /tmp/personal-os-messages.txt YYYY-MM-DD` を実行

  **routine.sh 内部処理:**
  1. テーマ更新: themes/配下の5ファイルをGemini CLIで更新
  2. synthesis更新: synthesis/synthesis.mdをGemini CLIで更新
  3. 活動ログ生成: todo/log/YYYY-MM-DD.md 作成・weekly.md確認
  4. git commit & push

- Gemini呼び出し方式: `--approval-mode plan`（ファイル注入方式）
  - シェルがファイル内容をプロンプトに注入 → Geminiが構造化出力 → シェルがパース・書き戻し
  - 詳細: `hub/docs/04_tooling_lessons.md` 参照

### ステップ3: Write Fragments 実行（n8n Codeノード・並行）
- `scripts/write-fragments.sh /tmp/personal-os-messages.txt YYYY-MM-DD` を実行
- #discoveriesの投稿 → `research/fragments/YYYY-MM-DD_slug.md`
- #research-queueの投稿 → `research/queue/YYYY-MM-DD_slug.md`
- 完了後 rclone sync で Google Drive（`gdrive:personal-os/fragments`）に同期

### ステップ4: Slack通知（n8n）
- #dailyチャンネル（ID: C0AT6CBAJ1W）に完了通知
- routine.shのstdout（テーマ更新・synthesis・ログ・gitの結果サマリ）を投稿

---

## 認証・接続情報

| サービス | 認証方法 |
|---|---|
| Slack | n8n環境変数（Bot Token） |
| Gemini CLI | `gemini auth login`（個人アカウント OAuth） |
| GitHub | SSH（`~/.ssh/id_ed25519_m1personal`） |
| Google Drive | rclone（remote名: `gdrive`） |

---

## ファイル構成

```
personal-os/
  scripts/
    routine.sh              … メインルーティンスクリプト
    write-fragments.sh      … Fragments書き出しスクリプト
    push-to-drive.sh        … Drive手動同期スクリプト
    prompts/
      update-themes.txt     … Step1プロンプト
      update-synthesis.txt  … Step2プロンプト
      generate-log.txt      … Step3プロンプト
  themes/                   … テーマ別歯車追跡ファイル（5つ）
  synthesis/synthesis.md    … テーマ横断接続メモ
  research/
    fragments/              … #discoveriesのMarkdownファイル
    queue/                  … #research-queueのMarkdownファイル
  todo/
    weekly.md               … 週次タスク管理
    log/                    … 日次活動ログ（YYYY-MM-DD.md）
  routine-detail.log        … 実行ログ（デバッグ用）
```

---

## コミット規約

| prefix | 意味 |
|---|---|
| [routine] | n8n自動処理 |
| [human+claude] | 対話を経た更新 |
| [human] | ひとりでの直接編集 |

---

## トラブルシュート

- Geminiがハングする → `--yolo`モードが混入していないか確認。`--approval-mode plan`のみ使用すること
- routine-server.pyが応答しない → LaunchAgent（`com.personal-os.routine-server.plist`）の状態を確認
- rclone syncが失敗する → `rclone listremotes` で `gdrive:` の存在を確認
- 詳細な知見 → `hub/docs/04_tooling_lessons.md`
