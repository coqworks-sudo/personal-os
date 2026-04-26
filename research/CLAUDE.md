# research/ — Fragmentsナレッジストア

Slackの `#discoveries` / `#research-queue` 投稿を構造化して保存するディレクトリ。

## ディレクトリ構成

```
research/
├── CLAUDE.md          # このファイル
├── fragments/         # #discoveries 投稿から生成された洞察・アイデア
│   └── YYYY-MM-DD_slug.md
└── queue/             # #research-queue 投稿の処理済みアーカイブ
    └── YYYY-MM-DD_slug.md
```

## Markdownフロントマター形式

```yaml
---
source: slack/#discoveries
date: YYYY-MM-DD
tags: [タグ1, タグ2]
summary: 一行要約
---
```

## 運用フロー

```
Slack投稿
  └─ n8n Routine（定期）
       ├─ Gemini CLI で整形・タグ付け・要約生成
       ├─ fragments/ または queue/ に .md として書き出し
       └─ rclone sync → Google Drive へ同期
```

- `fragments/` : #discoveries の投稿（洞察・アイデア）
- `queue/` : #research-queue の投稿（調査依頼・処理済み）
- ファイル名規則: `YYYY-MM-DD_keyword-slug.md`
