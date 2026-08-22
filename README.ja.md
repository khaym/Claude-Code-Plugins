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

[wsl-relay](https://github.com/khaym/wslconnector) 経由で、Claude CodeのイベントをWindowsデスクトップ通知として受け取り、タスク実行中のホストスリープを抑止します。タスク完了や権限リクエスト時に通知が届き、離席中にPCがスリープしてタスクが中断されることもなくなります。

**特徴:**
- フック自動登録 — インストール後すぐに動作、手動設定不要
- **Stop** イベント → 「Task completed」通知
- **Notification (permission_prompt)** イベント → 「Permission required」通知
- タスク実行中のスリープ抑止: プロンプト送信で開始、ツール実行ごとに更新、停止・権限待ちで解除。セッションが異常終了してもrelay側のTTL（既定10分）で自動解除。ディスプレイ消灯は妨げません
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
| `WSL_NOTIFY_POWER_INHIBIT` | `1` | `0` でスリープ抑止を無効化 |
| `WSL_NOTIFY_POWER_TTL` | relay既定値（600） | 抑止のTTL秒数（自動解除までの期限） |

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

### ticket-authoring

チケットを**ユーザーストーリー**として起票します — 1 チケット = 利用者が得る 1 つの能力。チケットの主語にコードの語彙が来ると、一番大事なこと — 何を作りたいのか・誰のどんな価値か・なぜ作るのか — が欠落し、手段が目的化します。そのツケは後から来ます: 既存コードにこだわり確認の段階でアプローチごと見直すしかなくなる手戻り、読めなくなるチケット間の依存関係、他チケットの改修でコードが変わったとたんに見失われる「やるべきこと」。ユーザーストーリーはその抗体で、チケットをコードに無効化されない価値へ係留します — 目的は外部の現象（利用者に見える挙動・次の公開・特定の人の手戻り）に、判断依頼は成果の語彙に。

`ticket-review` カスタム SubAgent は、草稿や既存チケットを分離コンテキスト — コードを知らない読者、すなわちコード係留の検出器 — で監査し、読み取り専用の指摘レポートを返します。レポートには「このチケットの価値の 1 行復元」（復元できなければ、それ自体を最大の指摘として明記）が含まれます。

**仕組み:**
- **単位は 1 つ** — 1 チケット = 利用者が得る 1 つの能力。実装ステップは Done のチェックリストに畳み、単独チケットにしない
- **5 つの前提チェック（T1–T5）** — 判別テスト / 目的の係留 / 成功条件の視点 / 判断依頼の語彙 / 境界と依存（起票時のセルフチェックと ticket-review エージェントで共用）
- **価値の係留先の解決** — 「利用者」が誰かを、呼び出し時の指定 → リポジトリの CLAUDE.md / README の目的節 → 汎用基準（外部の行為者＋観測可能な現象）の順で解決し、見つからなければその欠如も報告
- **トラッカー非依存** — 貼付草稿・ファイルはどこでも監査可能。姉妹プラグイン task-tracker がインストール済みならチケット ID を直接解決

文章の一読性は docs-authoring の領分のまま — 2 つのプラグインは合成して使えます（構造と前提はこちら、一読できる文章はあちら）。

**使い方:**

```
オフライン進行の上限のチケットを起票して
このチケットをレビューして   （ticket-review エージェントに振り分け）
loop-ready にする前に #42 を監査して
```

### gnome-loop

開発パイプラインのプラグイン — 開発の方法論と、それを回す機構。**dev-cycle** スキルを入れると、セッションが起票からクローズまで一本の規律で走るようになります: コードに触れる前に事実を実物で観測する、チケットはユーザー価値の単位で切る、実装より先にルールをテストで固定する、コード変更が終わると頼まなくても要件充足からレビューする、あなたの確認なしにはクローズしない。CLAUDE.md に足すのはトリガ行 1 行だけ——方法論そのものは invoke で読み込まれ、plugin の更新でプロジェクト横断に改善されていきます。方法論のドキュメントをプロジェクトごとに書いて維持する必要はありません。

**gnome-loop** スキルは、あなたが loop-ready にしたチケットを自律周回で消化します——worktree で実装し（定型はプロジェクトのレーンスキル、それ以外は同梱の implementer エージェント）、要件第一でレビューし、動く証拠を添えて「人間の確認待ち」まで運ぶ。マージはあなたの承認返信でだけ実行されます。あなたが次のチケットを検討している間に、AI が前のチケットを実装している——その並走を安全に保つ仕組み（セッション排他・状態機械・停止条件）ごと持ち込めます。

**動作の仕組み:**
- **CLAUDE.md に書くのは 1 行＋プロジェクト固有の宣言だけ** — トリガ行と、「このプロジェクトで動かせない事実は何か・どの自動テストが品質の網か・コミット/push/クローズは誰が承認するか」。手順の本体はスキルが持ち、セッションがコード変更の前に読み込みます
- **手戻りを上流で止める** — 事実の観測と価値単位の計画がコードに触れる前に必ず挟まるので、「作ってから要件と違うと気づく」型の手戻りが減ります。仕上げの code-review も要件充足の検証から始まります
- **姉妹プラグインと合成** — 起票の質は ticket-authoring（ticket-review）、文書の一読性は docs-authoring、チケット管理はトラッカーが担い、サイクルの決まった段で自動的に発火します
- **判断の門は人間側** — 周回が拾うのは loop-ready を付けたチケットだけ、マージは承認返信を受けたときだけ。詰まったら「何の判断が要るか」を 1 行目にして止まります
- **ロードマップ** — 導入（前提監査・スロット生成・トリガ行設置）を対話一回にする onboarding スキルが後続バージョンで載ります

**使い方:**

```
/gnome-loop:dev-cycle      （コード変更を伴う作業の前に）
/gnome-loop:gnome-loop     （周回を 1 周。/loop と組めば自走）
このプロジェクトの開発の進め方は？
```

### decision-queue

会話ログは線形で、見えるのは最新の話題だけ——複数の質問があなたの回答を待っていると、古いものから視界の外に落ちていきます。decision-queue は判断待ちの全量を視界に留めます: あなたの判断を待つ事項が発生すると Claude がセッション単位のキューのファイルに 1 行追記し、回答すると削除。statusline レンダラがその全行を入力欄の下に常駐表示します。判断待ちがない間、statusline は沈黙します。

**特徴:**
- あなたの回答待ちになっている判断事項を、件数付き・1 件 1 行で入力欄直下に常駐表示——キューが空なら何も表示しない
- キューのファイルはセッションごとに 1 つ: 並行セッションの項目は混ざらない。SessionStart hook が context 注入で自セッションのファイルパスを Claude に伝える
- 自己修復する登録: hook がセッション開始のたびに安定パス `~/.claude/decision-queue/statusline.sh` をインストール済みバージョンへ張り直すため、plugin 更新後も次のセッション開始で登録が復元される
- キューのファイルはセッション終了時に削除（`--resume` は同一セッション扱いでキューも維持）。hook が発火せず死んだセッションの残骸は 30 日で回収

**前提:**
- `jq` が PATH にあること

**セットアップ（初回のみ）:** Claude Code の plugin は `statusLine` 設定を同梱できないため、一度だけ手動で登録します。plugin をインストールし、セッションを 1 回起動（hook が安定パスを作成）した後、settings ファイル（例: `~/.claude/settings.json`）に追記:

```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/decision-queue/statusline.sh"
}
```

**使い方:** 呼び出しは不要——同梱スキルが規約を担い、判断待ちの発生・回答に応じて項目が増減します。直接指示することもできます:

```
リリース時期の相談を判断待ちキューに入れて
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
/plugin install ticket-authoring@khaym-claude-plugins
/plugin install gnome-loop@khaym-claude-plugins
/plugin install decision-queue@khaym-claude-plugins
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
