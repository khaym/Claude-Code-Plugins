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

### checking-oss-release

OSSプロジェクトのリリース前にセキュリティ漏洩・プライバシー問題・ライセンスコンプライアンスをチェックします。git pre-commitフックのセットアップも可能。

**特徴:**
- 3つのモード: Setup（pre-commitフック設置）、Quick（ステージングファイルのチェック）、Full（全ファイル監査）
- シークレットパターン検出（APIキー、秘密鍵、AWS認証情報、GitHubトークン等）
- Git emailプライバシーチェック（noreplyアドレスの強制）
- .gitignoreカバレッジ検証
- 依存パッケージのライセンス互換性スキャン（ライセンスマトリクス付き）
- THIRD_PARTY_LICENSES帰属表示チェック
- pre-commitフックスクリプト同梱

**使い方:**

```
OSSリリースチェックを実行して
pre-commitフックをセットアップして
ステージングファイルのセキュリティチェック
リリース前の完全監査を実行
```

### designing-test-cases

確立されたテスト技法に基づく体系的なテストケース設計をガイドします。技術スタック非依存で、TDD（テスト駆動開発）と互換性があります。

**特徴:**
- 2つのワークフロー: 新規テスト設計と既存テストレビュー（ギャップ分析）
- 7つのテスト設計技法: 同値分割、境界値分析、Null/Undefinedハンドリング、型ミスマッチ、状態遷移、組み合わせ/相互作用、エラー/例外
- 構造化されたテストケースマトリクス出力（技法 × 入力 × 期待結果）
- ルール・チェックリスト・実例付きの詳細な技法リファレンス

**使い方:**

```
ログイン機能のテストケースを設計して
これらのテストは十分？テストカバレッジをレビューして
どの境界値をテストすべき？
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
/plugin install checking-oss-release@khaym-claude-plugins
/plugin install designing-test-cases@khaym-claude-plugins
```

### アップデート

```
/plugin marketplace update khaym-claude-plugins
```


## ライセンス

MIT
