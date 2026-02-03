# Proposal: Template Sync System

## Why

Organization内の50以上のリポジトリに対し、共通設定ファイル（CI/CDワークフロー、Lint設定、TypeScript設定など）を一元的に管理・配布する仕組みが不足している。

現状、各リポジトリが個別に設定を管理しており、更新時に手動作業が必要となっている。これにより、設定の乖離が発生し、セキュリティパッチやベストプラクティスの適用が遅れる問題がある。

## What Changes

- **共通設定リポジトリ（demo-template-sync）の構築**
  - 配布元となる親リポジトリを確立
  - 配布対象ファイルをホワイトリスト形式（`includes.txt`）で管理

- **git-xargsによる自動配布システムの導入**
  - GitHub Actionsで定期実行（毎週）と手動実行の両方に対応
  - 並列処理による高速な一括配布
  - プルリクエスト形式で各リポジトリ担当者がコンフリクトを解決可能に

- **GitHub App認証の導入**
  - 安全なOrganization-wideなアクセス権限管理
  - PATよりも安全で管理しやすい認証方式

- **柔軟な配布対象制御**
  - パターンマッチングによるグループ配布（例: `frontend-*`）
  - 特定リポジトリ向けの個別配布
  - 全リポジトリへのデフォルト配布

## ツール選定の経緯

**比較検討したツール:**

| ツール | 特徴 | 採用可否 |
|--------|------|----------|
| actions-template-sync | 各ターゲットリポジトリにActionを配置必要 | ❌ 50+リポジトリで運用コストが高い |
| git-xargs | 中央管理、並列実行、CLIツール | ⭐ 採用 |

**git-xargsを採用した理由:**
- 中央管理: 1箇所から全リポジトリを制御可能
- 並列実行: goroutinesによる高速処理
- 柔軟性: スクリプトで自由なロジックを実装可能
- GitHubネイティブ: Organization単位の操作に最適化

## Capabilities

### New Capabilities

- `config-distribution`: 共通設定ファイルを複数リポジトリに配布する機能
- `github-app-auth`: GitHub Appを使用した安全な認証機能
- `include-file-format`: 配布対象ファイルを定義する`includes.txt`の仕様
- `sync-scheduler`: スケジュール・手動ハイブリッドな配布実行機能

### Modified Capabilities

なし（新規システムのため）

## Impact

**影響を受けるリポジトリ:**
- 50以上の子リポジトリ（テスト用に`demo-template-sync-{a,b,c}`を作成して検証）

**依存関係の追加:**
- git-xargs (CLIツール)
- GitHub App (新規作成)

**プロセスの変更:**
- 設定更新: 各リポジトリ個別 → `includes.txt`の一元管理
- 配布方法: 手動コピー → 自動プルリクエスト作成
- コンフリクト解決: 各リポジトリ担当者がPRで対応

**導入フェーズ:**
1. テスト環境: `demo-template-sync-{a,b,c}` の3リポジトリで検証
2. ステージング: 約20リポジトリに展開
3. 本番: 全50+リポジトリに適用
