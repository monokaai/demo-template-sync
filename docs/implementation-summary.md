# 実行内容サマリー

## 作成日
2025-02-03

## 実装した内容

### 1. ディレクトリ構成

```
demo-template-sync/
├── .github/
│   └── workflows/
│       ├── ci.yml         # サンプルCIワークフロー
│       ├── lint.yml      # サンプルLintワークフロー
│       └── distribute.yml # メイン配布ワークフロー
├── scripts/
│   ├── apply.sh          # 各ターゲットリポジトリ内で実行
│   └── sync.sh           # git-xargsラッパースクリプト
├── repos/
│   ├── test.txt          # テスト用リポジトリリスト
│   └── production.txt    # 本番用リポジトリリスト
├── docs/
│   └── github-app-setup/
│       └── README.md      # GitHub App作成手順
├── includes.txt          # 配布対象ファイル定義
├── .eslintrc.json        # サンプルESLint設定
├── .prettierrc           # サンプルPrettier設定
└── tsconfig.json         # サンプルTypeScript設定
```

---

### 2. scripts/apply.sh

**目的**: 各ターゲットリポジトリ内で実行され、配布元リポジトリからファイルをコピーする

**主な機能**:
- 配布元リポジトリのクローン（キャッシュ対応）
- includes.txt のパース（コメント/空行のスキップ）
- パターンマッチング（`pattern:filepath` 形式）
- ファイルコピー（ディレクトリ自動作成）
- ログ出力（コピー済み/スキップ済みファイル数）

**環境変数**:
- `XARGS_REPO_NAME`: git-xargs から提供されるターゲットリポジトリ名
- `SOURCE_REPO`: 配布元リポジトリ（デフォルト: monokaai/demo-template-sync）

---

### 3. scripts/sync.sh

**目的**: git-xargs を使用して複数リポジトリに一括配布する

**主な機能**:
- git-xargs の自動インストール（最新リリースを取得）
- タイムスタンプ付きブランチ名の生成
- Draft PR 作成
- dry-run モード対応
- 環境変数チェック（GITHUB_OAUTH_TOKEN）

**パラメータ**:
- `SOURCE_REPO`: 配布元リポジトリ
- `BRANCH_NAME`: ブランチ名（デフォルト: update-config-YYYYMMDDHHMM）
- `COMMIT_MESSAGE`: コミットメッセージ
- `PR_TITLE`: PRタイトル
- `REPOS_FILE`: ターゲットリポジトリリスト（デフォルト: repos/test.txt）
- `DRY_RUN`: dry-run モード（デフォルト: false）

---

### 4. .github/workflows/distribute.yml

**目的**: GitHub Actions で定期実行・手動実行を制御

**トリガー**:
- **スケジュール実行**: 毎週月曜 2:00 JST
- **手動実行**: workflow_dispatch で実行

**入力パラメータ**:
- `batch`: ターゲットバッチ（test/production）
- `dry_run`: dry-run モード

**処理フロー**:
1. GitHub App トークン生成
2. リポジトリのチェックアウト
3. git-xargs のインストール
4. scripts/sync.sh の実行

**権限**:
- `contents: write`
- `pull-requests: write`

---

### 5. includes.txt

**形式**:
```
# コメント行
# フォーマット: [パターン:]ファイルパス

# 全リポジトリに配布
.github/workflows/ci.yml
.eslintrc.json

# パターンマッチング（例: frontend-* 系のみ）
# frontend-*:.github/workflows/deploy-preview.yml

# 特定リポジトリのみ（例: demo-template-sync-a のみ）
# demo-template-sync-a:config/custom-a.json
```

**評価ロジック**:
1. パターンプレフィックスあり → 子リポジトリ名がパターンにマッチすれば配布
2. パターンプレフィックスなし → 全リポジトリに配布

---

### 6. テスト用リポジトリ

作成したリポジトリ:
- https://github.com/monokaai/demo-template-sync-a
- https://github.com/monokaai/demo-template-sync-b
- https://github.com/monokaai/demo-template-sync-c

---

## 進捗

| タスク | 状態 |
|------|------|
| GitHub Appの作成 | ⏸️ ドキュメント作成済み。Web操作待ち。 |
| テスト用リポジトリ作成 | ✅ 3/4 完了 |
| includes.txt | ✅ 完了 |
| scripts/apply.sh | ✅ 完了 |
| scripts/sync.sh | ✅ 完了 |
| GitHub Actions workflow | ✅ 完了 |
| 共通ファイル配置 | ✅ 完了 |
| GitHub Appドキュメント | ✅ 完了 |
| テスト実行 | ⏸️ GitHub App作成待ち |

**全体進捗**: 36/49 タスク完了

---

## 次のステップ

1. **GitHub App の作成**: [docs/github-app-setup/README.md](docs/github-app-setup/README.md) の手順に従って作成
2. **Secrets の登録**: APP_ID と APP_PRIVATE_KEY を登録
3. **テスト実行**: GitHub Actions の workflow_dispatch で手動実行
