# Claude Code Plugins

[English](README.md)

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) の開発ワークフロー向けプラグインコレクション。

## プラグイン一覧

### task-tracker

TSVファイルとシェルスクリプトによる軽量タスク/チケットトラッカー。Claude Codeの[組み込みTask List](https://code.claude.com/docs/en/interactive-mode#task-list)がClaude内部で作業ステップを自動管理するのに対し、task-trackerはTSVとMarkdownで人間が直接読み書きできる形式でタスクを管理します。

**特徴:**
- TSV + Markdownによる人間が読める形式（`.tasks/`）
- スラッシュコマンド: `/task-tracker:add`, `/task-tracker:list`, `/task-tracker:show`, `/task-tracker:update`, `/task-tracker:close`
- カテゴリ分類: `bug`, `improvement`, `task`
- 開発中に発見した問題をClaudeが自動トラッキングするスキル付き

**使い方:**

```
/task-tracker:add ログインボタンが反応しない問題を修正
/task-tracker:add bug: 空のペイロードでAPIが500を返す
/task-tracker:list
/task-tracker:list all
/task-tracker:show 1
/task-tracker:update 1 -s "更新されたタイトル"
/task-tracker:close 1 ハンドラーの更新で修正
```

### skill-authoring

Claude Codeの[Agent Skills](https://code.claude.com/docs/en/skills)の作成・レビューを標準化されたワークフローと品質チェックリストでガイドします。

**特徴:**
- インテント検出: 「スキルを作成」「スキルをレビュー」で適切なワークフローを自動選択
- 8ステップの作成ワークフロー（実行パターン選定・トークン最適化ガイダンス付き）
- 6ステップのレビューワークフロー（6カテゴリ27項目のチェックリスト評価）
- 標準ルールと推奨プラクティスを網羅した共通ガイドライン
- カスタムSubAgent定義リファレンス

**使い方:**

```
Slack通知チェック用のスキルを作成して
task-trackerスキルをレビューして
スキル作成のガイドラインを教えて
```

## インストール

### マーケットプレイスの追加

```
/plugin marketplace add khaym/khaym-claude-plugins
```

### プラグインのインストール

```
/plugin install task-tracker@khaym-claude-plugins
/plugin install skill-authoring@khaym-claude-plugins
```

### アップデート

```
/plugin marketplace update khaym-claude-plugins
```


## ライセンス

MIT
