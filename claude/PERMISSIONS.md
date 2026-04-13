# PERMISSIONS — Claude Codeの権限設定

_設定日：2026-04-13_
_設定ファイル：`~/.claude/settings.json`_

---

## 基本方針

- 作業範囲は `~/Claude-Workspace/` 以内に限定
- 変更を伴う操作（push・デーモン登録・グローバルインストール）は事前に声をかける
- リストにない操作・サイトは必ず承認を求めてから実行する

---

## 自動許可（確認なしで実行）

### Bashコマンド

| カテゴリ | 許可パターン | 用途 |
|---|---|---|
| git | `git *` | リポジトリ操作 |
| SSH | `ssh *` / `ssh-keygen *` | GitHub接続確認・鍵生成 |
| n8n | `n8n *` / `npx n8n*` | 起動・デーモン化 |
| launchctl | `launchctl *` | macOSデーモン登録 |
| curl | `curl https://slack.com/api/*` | Slack API疎通確認（Slack APIのみ） |
| npm | `npm install -g *` | グローバルパッケージ管理 |
| brew | `brew install *` | ツール追加 |
| ファイル操作 | `find` / `ls` / `mkdir` / `touch` / `chmod` | 環境確認・構造作成 |
| SSH設定確認 | `cat ~/.ssh/*` | 鍵ファイル確認 |
| パス確認 | `which *` | コマンド存在確認 |

### ファイル操作

| パターン | 操作 |
|---|---|
| `~/Claude-Workspace/personal-os/**` | 読み取り・編集・書き込み（自動許可） |
| それ以外のパス | 確認ダイアログ |

### ウェブアクセス（読み取り専用）

| サイト | 用途 |
|---|---|
| `docs.n8n.io` | n8nドキュメント参照 |
| `api.slack.com` | Slack APIドキュメント参照 |
| `docs.anthropic.com` | Claude APIドキュメント参照 |
| `docs.github.com` | GitHub APIドキュメント参照 |

- **全サイト共通：読み取りのみ。ログイン・フォーム送信・API呼び出しは行わない**
- **新しいサイトへのアクセスが必要な場合は必ず事前承認を求める**

### Slack MCPツール

| ツール | 用途 |
|---|---|
| `slack_send_message` | チャンネルへの送信 |
| `slack_read_channel` | チャンネル読み取り |
| `slack_read_thread` | スレッド読み取り |
| `slack_search_channels` | チャンネル検索 |

---

## 自動拒否（実行不可）

| 対象 | 理由 |
|---|---|
| `WebSearch` | 検索エンジンへのアクセス不要 |
| `slack_create_canvas` | 不要な操作 |
| `slack_update_canvas` | 不要な操作 |
| `slack_schedule_message` | 不要な操作 |
| `slack_send_message_draft` | 不要な操作 |

---

## 確認ダイアログが出るもの

上記リストに含まれないコマンド・サイト・ツールはすべて都度確認する。
