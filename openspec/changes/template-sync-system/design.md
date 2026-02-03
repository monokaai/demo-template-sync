# Design: Template Sync System

## Context

### 現状
- Organization内に50以上のリポジトリが存在
- 各リポジトリが個別に設定ファイル（CI/CD、Lint、TypeScript等）を管理
- 設定更新時に手動コピー作業が必要で、設定の乖離が発生している

### 制約
- **GitHub Organization**: 単一のOrganization内に全リポジトリが存在
- **認証方式**: GitHub Appを使用（PATより安全）
- **配布頻度**: 毎週実行、将来的には頻度を調整可能
- **管理スタイル**: 中央管理者が一括管理、各リポジトリ担当者がコンフリクト解決

### ステークホルダー
- 中央管理者: 設定の作成・配布実行
- 各リポジトリ担当者: コンフリクト解決・マージ判断

---

## Goals / Non-Goals

**Goals:**
- 共通設定ファイルを一元管理し、複数リポジトリに自動配布する
- ホワイトリスト形式で配布対象ファイルを柔軟に制御する
- プルリクエスト形式で安全に変更を通知する
- スケジュール実行と手動実行の両方に対応する

**Non-Goals:**
- 双方向同期（子リポジトリの変更を親に反映）
- 自動マージ（コンフリクト解決は担当者に委ねる）
- 設定ファイルの自動生成

---

## Decisions

### 1. ツール選定: git-xargs

**決定:** git-xargsを採用

**理由:**
- **中央管理**: 1箇所から全リポジトリを制御可能（actions-template-syncは各リポジトリに配置必要）
- **並列実行**: goroutinesによる高速処理（50+リポジトリで効果大）
- **柔軟性**: スクリプトで自由なロジックを実装可能
- **GitHubネイティブ**: Organization単位の操作に最適化

**検討した代替案:**
| ツール | メリット | デメリット | 結論 |
|--------|----------|-----------|------|
| actions-template-sync | GitHub Actionsネイティブ | 各リポジトリに配置必要（運用コスト高） | ❌ |
| git-xargs | 中央管理・並列実行 | CLIツール（GHAでラップ必要） | ⭐ 採用 |

---

### 2. 認証方式: GitHub App

**決定:** GitHub Appを使用

**理由:**
- PATよりも安全（トークンの有効期限・スコープ管理が容易）
- Organization-wideな権限管理が可能
- 監査ログが追跡可能

**権限設定:**
- Repository contents: Write
- Pull requests: Write
- Metadata: Read

---

### 3. 配布対象ファイル管理: includes.txt（超シンプル形式）

**決定:** 1ファイルのセクション形式ではなく、パターンプレフィックス形式を採用

**形式:**
```
# コメント行は # で始める
# フォーマット: [パターン:]ファイルパス

# パターンなし = 全リポジトリ
.github/workflows/ci.yml
.eslintrc.json

# frontend-* 系のみ
frontend-*:.github/workflows/deploy-preview.yml

# 特定リポジトリ
demo-template-sync-a:config/custom-a.json
```

**理由:**
- 1ファイルで完結（管理がシンプル）
- 直感的な構文（パターン:ファイルパス）
- パターンマッチングが柔軟

**評価ロジック:**
1. パターンプレフィックスあり → 子リポジトリ名がパターンにマッチすれば配布
2. パターンプレフィックスなし → 全リポジトリに配布

---

### 4. ディレクトリ構成

```
demo-template-sync/
├── .github/
│   └── workflows/
│       └── distribute.yml     # メインワークフロー
├── scripts/
│   ├── apply.sh               # 各リポジトリ内で実行
│   └── sync.sh                # git-xargs実行スクリプト
├── repos/
│   ├── test.txt               # テスト用リポジトリリスト
│   └── production.txt         # 本番用リポジトリリスト
├── includes.txt               # 配布対象ファイル定義
└── 【配布したいファイル実体】
    ├── .github/
    ├── .eslintrc.json
    └── ...
```

---

### 5. スクリプト設計

**scripts/apply.sh**（各ターゲットリポジトリ内で実行）

```bash
#!/bin/bash
set -euo pipefail

# 配布元リポジトリを取得
SOURCE_REPO="monokaai/demo-template-sync"
SOURCE_DIR="/tmp/common-config-source"

if [[ ! -d "$SOURCE_DIR" ]]; then
  git clone --depth 1 "https://github.com/${SOURCE_REPO}.git" "$SOURCE_DIR"
fi

REPO_NAME="${XARGS_REPO_NAME}"

# includes.txt を解析してコピー
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue

  if [[ "$line" == *:* ]]; then
    pattern="${line%%:*}"
    file="${line#*:}"

    # パターンマッチ（ワイルドカード展開）
    if [[ "$REPO_NAME" == ${pattern} ]]; then
      cp "$SOURCE_DIR/$file" "$file" 2>/dev/null || true
    fi
  else
    # パターンなし = 全リポジトリ
    cp "$SOURCE_DIR/$line" "$line" 2>/dev/null || true
  fi
done < "$SOURCE_DIR/includes.txt"
```

---

## Risks / Trade-offs

### [Risk] 50+リポジトリでのレートリミット
**懸念:** GitHub APIのレートリミットに達する可能性

**軽減策:**
- git-xargsの `--seconds-between-prs` フラグで間隔を調整（デフォルト: 1秒）
- バッチ処理で徐々にリポジトリ数を増やす
- 並列クローン数を制限（`--max-concurrent-clones`）

---

### [Risk] コンフリクトの多発
**懸念:** 多数のリポジトリでコンフリクトが発生し、解決コストが増大

**軽減策:**
- テスト環境（3リポジトリ）で検証
- Draft PRで通知し、各担当者が確認可能にする
- dry-runモードで事前に確認可能にする

---

### [Risk] 誤ったファイルの配布
**懸念:** includes.txtの設定ミスで意図しないファイルが配布される

**軽減策:**
- ホワイトリスト方式（明示的なファイルのみ配布）
- バッチ処理で小規模環境から開始
- PR通知により変更内容を可視化

---

## Migration Plan

### フェーズ1: テスト環境（1週目）

1. **テスト用リポジトリ作成**
   - `demo-template-sync-a`
   - `demo-template-sync-b`
   - `demo-template-sync-c`

2. **基本構築**
   - GitHub Appの作成と設定
   - `includes.txt` の作成
   - `scripts/apply.sh` の実装

3. **動作確認**
   - 手動実行で動作確認
   - dry-runモードでの検証
   - PRの作成とマージ確認

---

### フェーズ2: ステージング（2週目〜）

1. **約20リポジトリに展開**
   - `repos/staging.txt` にターゲットリポジトリを記載
   - 定期実行のスケジュール設定

2. **調整**
   - コンフリクト発生状況の監視
   - レートリミット問題の確認

---

### フェーズ3: 本番（3週目以降）

1. **全50+リポジトリに適用**
   - `repos/production.txt` に本番リポジトリを記載

2. **運用開始**
   - 毎週月曜 2:00 JST に定期実行
   - 必要に応じて手動実行

---

### ロールバック戦略

- **即時ロールバック**: GitHub Actionsを無効化
- **ファイル削除**: 各リポジトリのPRをクローズ
- **設定復旧:** includes.txt をバックアップから復元

---

## Open Questions

1. **GitHub Appの作成手順**: 具体的な作成手順をドキュメント化する必要がある
2. **includes.txtのパターンマッチング詳細**: 正規表現のサポート範囲を確定する
3. **エラーハンドリング**: ファイルコピー失敗時のログ出力方法
