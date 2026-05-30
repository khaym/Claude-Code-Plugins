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
- 関連カラム（`blocked-by` / `related`）を `list` に表示し、着手判断を一目で把握
- 開発中に発見した問題をClaudeが自動トラッキングするスキル付き

**使い方:**

```
/task-tracker:add ログインボタンが反応しない問題を修正
/task-tracker:add bug: 空のペイロードでAPIが500を返す
/task-tracker:list
/task-tracker:list all
/task-tracker:show 1
/task-tracker:update 1 -s "更新されたタイトル"
/task-tracker:update 2 -b "1,4"
/task-tracker:close 1 ハンドラーの更新で修正
```

### skill-authoring

Claude Code [Agent Skills](https://code.claude.com/docs/en/skills) のためのコンテキスト設計フレームワーク。Claudeのパフォーマンスは受け取るコンテキストに依存します。このプラグインは、Claudeに適切な情報を適切なタイミングで渡すスキルを設計するための原則とワークフローを提供します。

**設計原則:**
- **コンテキスト設計** — 各スキルのコンテキストに入る情報・処理中の情報・出力される情報を制御し、Claudeの精度を最大化
- **実行パターン選択** — タスクごとに最適な分離レベル（メインセッション、context:fork、組み込み/カスタムSubAgent）を選択
- **スキル合成** — 複数エージェントがドメイン知識を共有する場合、内容の複製や脆い相互参照ではなく `skills` フィールドによる依存性注入（DI）を使用
- **品質チェックリスト** — 6カテゴリ28項目の評価（コンテキスト設計、構造、フロントマター、コンテンツ、design.md、スクリプト）

**ワークフロー:**
- **作成**: 要件整理 → パターン選定 → 設計 → 構造設計 → 実装 → 品質チェック → テスト
- **レビュー**: 読み込み → ガイドライン照合 → チェックリスト評価 → 改善提案 → レポート

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

### hardening-dev-environment

Claude Code を使う開発環境のための多層防御プラグイン。npm/PyPI サプライチェーン攻撃、prompt injection 経由のスコープ拡大、credential 流出、設定ファイル改ざんによる persistence、取得コンテンツ経由の間接 prompt injection — それぞれ独立した攻撃クラスを別レイヤーで対処します。各レイヤーは補完関係にあり、静的設定で予防し、ランタイム hook で既知の bypass を検出し、auto-mode classifier がスコープを制御し、trust-boundary リマインダで取得コンテンツの解釈を制約します。

**多層防御マップ:**

| # | レイヤー | 担当 | 対処する脅威 |
|---|---------|------|-------------|
| 1 | Auto-mode classifier + 設定 | `hardening-auto-mode`（Claude Code v2.1.83+、プラン制限あり） | スコープ拡大、信頼できないインフラ、prompt injection 由来のアクション |
| 2 | 静的 `permissions.{deny, ask}` ルール | `hardening-claude-permissions` | 設定ファイル改ざんによる persistence、credential ファイル流出、プラグイン著作経路の確認ゲート |
| 3 | 同梱ランタイム hook（自動有効） | このプラグイン（`sensitive-bash-guard`, `package-json-scripts-guard`, `pyproject-buildsystem-guard`, `untrusted-content-reminder`） | Bash 経由の credential 読み取り bypass、`package.json` `scripts` 改ざん、`pyproject.toml [build-system]` / `setup.py` 改ざん、`WebFetch` 結果由来の間接 prompt injection |
| 4 | WebFetch trust discipline | `hardening-untrusted-content` | 間接 prompt injection — trust-boundary チェックリスト + PostToolUse hook を駆動する vendor allowlist |
| 5a | npm サプライチェーン設定 | `hardening-pnpm-config` | 悪性パッケージのインストール / install スクリプト実行 / 未ピンの `npx` |
| 5b | PyPI サプライチェーン設定 | `hardening-uv-config` | 直近に公開された悪性パッケージのインストール / dependency confusion / 未ピンの `pip install` / `pipx run`、レガシー pip / setup.py プロジェクトの uv 移行 |
| 6 | Pre-commit シークレット scan | `checking-oss-release` プラグイン（兄弟プラグイン） | コミット時に到達するプレーンテキストの secret |

レイヤー 3 の hook はプラグイン有効化と同時に自動起動します。レイヤー 1 はプランによって利用可否が決まる Claude Code のランタイム機能です。それ以外のレイヤーは担当 skill から適用します。

**最初のとっかかり:** Claude に *Claude Code のハードニング状況を点検して* と依頼すると、`hardening-overview` が各レイヤーの現状を点検し、プロジェクトのプラン階層・ユースケースに応じたセットアップ順を提案します。

**使い方:**

```
Claude Code のハードニング状況を点検して
```

### wsl-notify

[wsl-relay](https://github.com/khaym/wslconnector) 経由でClaude CodeのイベントをWindowsデスクトップ通知として受け取ります。タスク完了や権限リクエスト時に通知が届くため、ターミナルを見続ける必要がなくなります。

**特徴:**
- フック自動登録 — インストール後すぐに動作、手動設定不要
- **Stop** イベント → 「Task completed」通知
- **Notification (permission_prompt)** イベント → 「Permission required」通知
- スラッシュコマンド: `/wsl-notify:test-notify` で接続確認
- 環境変数でカスタマイズ可能（`WSL_RELAY_HOST`, `WSL_RELAY_PORT`, メッセージ変更）

**前提条件:**
- Windowsホストで [wsl-relay](https://github.com/khaym/wslconnector) が動作していること

**使い方:**

```
/wsl-notify:test-notify
```

**環境変数:**

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `WSL_RELAY_HOST` | `host.docker.internal` | wsl-relayのホストアドレス |
| `WSL_RELAY_PORT` | `9400` | wsl-relayのポート |
| `WSL_NOTIFY_STOP_TITLE` | `Claude Code` | Stop通知のタイトル |
| `WSL_NOTIFY_STOP_BODY` | `Task completed` | Stop通知の本文 |
| `WSL_NOTIFY_PERMISSION_TITLE` | `Claude Code` | 権限通知のタイトル |
| `WSL_NOTIFY_PERMISSION_BODY` | `Permission required` | 権限通知の本文 |

### docs-authoring

設計ドキュメント・チケット・RFC を、**より短く・明快に**、読者が一読で理解できる文章にします。指針は Dieter Rams の **「Less, but better」** — 役割を果たさない語は削り、読者に本当に必要な事実は残す。テンプレートを埋めるのではなく、「読者が何を求めて来たか」を見極めて最短経路に並べます。新規執筆にも、長くなりすぎた既存文書の推敲にも使えます。

`docs-review` カスタム SubAgent は、仕上がった文書を分離コンテキストで監査し、読み取り専用の指摘レポートを返します（編集はせず診断のみ）。

**仕組み（ライティングモデル）:**
- **2フェーズ** — まず「名前を特定した読者の問い／意思決定」を特定し、それを一読できる最短経路に構造化
- **5原則** — 視点を1つに固定 / トップダウン（主張を根拠の前に） / 並列項目を独立に保つ / 読者の語彙の具体語を使う / スコープの境界を明示
- **語は減らすが事実は減らさない** — 空疎な言い回しや繰り返しは削り、収まらない事実は削除せず再配置
- **セルフレビュー** — 二値 OK/NG チェックリスト（docs-review エージェントと共用）で、冗長・視点のブレ・判断に必要な事実の欠落を出荷前に検出

**使い方:**

```
ルールエンジンの設計ドキュメントを書いて
このチケットを推敲して / もっと分かりやすくして
このドキュメントをレビューして   （docs-review エージェントに振り分け）
```

## インストール

### マーケットプレイスの追加

```
# HTTPS（推奨 — SSHキーの設定不要）
/plugin marketplace add https://github.com/khaym/Claude-Code-Plugins.git

# GitHub短縮形（github.comのSSHキー設定が必要）
/plugin marketplace add khaym/Claude-Code-Plugins
```

### プラグインのインストール

```
/plugin install task-tracker@khaym-claude-plugins
/plugin install skill-authoring@khaym-claude-plugins
/plugin install checking-oss-release@khaym-claude-plugins
/plugin install designing-test-cases@khaym-claude-plugins
/plugin install hardening-dev-environment@khaym-claude-plugins
/plugin install wsl-notify@khaym-claude-plugins
/plugin install docs-authoring@khaym-claude-plugins
```

### アップデート

```
/plugin marketplace update khaym-claude-plugins
```


## 開発環境のセットアップ

このマーケットプレイスにコントリビュートする場合、clone後に同梱の pre-commit フックを有効化してください:

```
git config core.hooksPath .githooks
```

これにより、すべての `git commit` でシークレット / Git email / .gitignore のチェックが実行されます（`checking-oss-release` プラグインが提供）。


## ライセンス

MIT
