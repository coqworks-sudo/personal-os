# #daily チャンネル運用マニュアル

## 概要

`#daily` は、personal-osシステムの毎日の自動ルーティン実行結果が届くチャンネルです。
n8nのワークフローが毎朝スケジュール実行され、personal-os-botが結果を投稿します。

---

## 投稿のフォーマット

```
[routine] ===== 開始: YYYY-MM-DD =====
[routine] Step 1: テーマ更新...
（Claudeによるテーマ更新の結果コメント）
[routine] Step 1: 完了
[routine] Step 2: synthesis更新...
（Claudeによるsynthesis更新の結果コメント）
[routine] Step 2: 完了
[routine] Step 3: 活動ログ生成...
（Claudeによる活動ログ生成の結果コメント）
[routine] Step 3: 完了
[routine] Step 4: git push...
（コミット・プッシュの結果）
[routine] ===== 終了: YYYY-MM-DD =====
```

---

## 各ステップの意味

### Step 1: テーマ更新
`#discoveries`・`#research-queue`・`#daily`（ユーザー投稿のみ）の過去24時間の投稿を読み、以下のテーマファイルを更新します。

| ファイル | 内容 |
|----------|------|
| `themes/ai-philosophy.md` | AI・哲学系の気づき |
| `themes/business-design.md` | ビジネス・デザイン系の気づき |
| `themes/personal-os.md` | personal-os自体に関する気づき |
| `themes/tools-tech.md` | ツール・技術系の気づき |
| `themes/misc.md` | その他 |

**更新ルール:**
- メッセージが該当するテーマファイルの「積層中の歯車」を更新
- 繰り返し現れる概念 → 「繰り返し現れる」に昇格
- 初出の概念 → 「新種」として追記
- 最近出てこない概念 → 「ダウントーン気味」に変更
- 該当なければ変更なし（「変更なし」と返す）

### Step 2: synthesis更新
全テーマファイルを横断して読み、`synthesis/synthesis.md` の「現在の接続仮説」を更新します。

- テーマをまたぐ意外な接続・パターンを優先
- 「かもしれない」「のような気がする」として断定しない
- 変化がなければスキップ（「変更なし」と返す）

### Step 3: 活動ログ生成
`todo/log/YYYY-MM-DD.md` を新規作成し、その日の収集メッセージを整理します。

**活動ログのフォーマット:**
```markdown
---
# 活動ログ YYYY-MM-DD

## #discoveries
（投稿内容を箇条書き。発言者名なし、内容だけ）

## #research-queue
（投稿内容を箇条書き。発言者名なし、内容だけ）

## #daily
（ユーザーが#dailyに書いたメモを箇条書き。発言者名なし、内容だけ。新着なしの場合は省略）

## まとめ
（3行以内で当日の活動の要点）
---
```

また `todo/weekly.md` を確認し、完了と判断できるタスクがあれば「完了済み」に移動します。

### Step 4: git push
変更があれば `[routine] YYYY-MM-DD` というメッセージでコミットし、GitHubにプッシュします。変更がなければスキップします。

---

## 読み方のポイント

### 正常な投稿の例
```
[routine] Step 1: テーマ更新...
ai-philosophy.md に「エージェントの自律性」を新種として追加しました。
[routine] Step 1: 完了
```
→ メッセージが届いて、テーマが更新された。

### メッセージがない日の例
```
[routine] Step 1: テーマ更新...
収集メッセージの内容を確認しました。両セクションが空です。
更新するべき実質的なメッセージが存在しないため、変更は行いません。
[routine] Step 1: 完了
```
→ 正常。その日に `#discoveries` / `#research-queue` への投稿がなかっただけ。

### エラーの場合
`[routine] Step X` の後に `完了` が来ず、ワークフローが止まっている場合はエラーです。
→ `~/Claude-Workspace/personal-os/routine-server.log` を確認してください。

---

## システム構成（参考）

```
n8n (Schedule Trigger)
  ↓ 毎朝スケジュール実行
Slack API → #discoveries の過去24h取得
Slack API → #research-queue の過去24h取得
Slack API → #daily の過去24h取得（ユーザー投稿のみ、bot投稿除外）
  ↓ メッセージ整形
HTTP Request → routine-server.py (localhost:5680)
  ↓ caffeinate付きで実行（スリープ防止）
routine.sh → Claude CLI × 3回
  ↓ 結果
Slack #daily に投稿
```

### 関連ファイル
| ファイル | 場所 |
|----------|------|
| ワークフロー本体 | n8n UI (http://localhost:5678) |
| routine.sh | `scripts/routine.sh` |
| routine-server.py | `scripts/routine-server.py` |
| サーバーログ | `routine-server.log` |
| 活動ログ | `todo/log/YYYY-MM-DD.md` |
| 週次TODO | `todo/weekly.md` |
| テーマファイル | `themes/*.md` |
| 接続仮説 | `synthesis/synthesis.md` |

---

## トラブル時の対処

### #dailyに投稿が来ない
1. Macがスリープしていなかったか確認
2. n8nが起動しているか確認: http://localhost:5678
3. routine-serverが起動しているか確認:
   ```bash
   lsof -i :5680
   ```
4. ログ確認:
   ```bash
   tail -50 ~/Claude-Workspace/personal-os/routine-server.log
   ```

### routine-serverが落ちている場合
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.personal-os.routine-server.plist
```

### n8nが落ちている場合
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.personal-os.n8n.plist
```
