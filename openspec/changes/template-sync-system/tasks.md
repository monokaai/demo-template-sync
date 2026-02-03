# Tasks: Template Sync System

## 1. GitHub Appの作成と設定

- [ ] 1.1 GitHub AppをOrganizationに作成する
- [ ] 1.2 GitHub Appに必要な権限を設定する
  - Repository contents: Write
  - Pull requests: Write
  - Metadata: Read
- [ ] 1.3 GitHub AppのPrivate KeyとApp IDを取得する
- [ ] 1.4 GitHub AppをOrganizationにインストールする
- [ ] 1.5 GitHub Appの認証情報をActions Secretsに登録する
  - `APP_ID`: GitHub AppのID
  - `APP_PRIVATE_KEY`: GitHub AppのPrivate Key

---

## 2. テスト用リポジトリの作成

- [ ] 2.1 `demo-template-sync-a` リポジトリを作成する
- [ ] 2.2 `demo-template-sync-b` リポジトリを作成する
- [ ] 2.3 `demo-template-sync-c` リポジトリを作成する
- [ ] 2.4 各リポジトリに初期コミットを作成する

---

## 3. includes.txtの作成

- [ ] 3.1 `includes.txt` をルートディレクトリに作成する
- [ ] 3.2 全リポジトリ向けのデフォルトファイルを定義する
  ```
  # 全リポジトリ共通
  .github/workflows/ci.yml
  .eslintrc.json
  ```
- [ ] 3.3 パターンマッチングの例を追加する（オプション）
- [ ] 3.4 特定リポジトリ向けのファイルを定義する（オプション）

---

## 4. scripts/apply.shの実装

- [ ] 4.1 `scripts/apply.sh` を作成する
- [ ] 4.2 配布元リポジトリのクローン処理を実装する
- [ ] 4.3 includes.txtのパース処理を実装する
  - コメント行（`#`）のスキップ
  - 空行のスキップ
  - パターンプレフィックスの解析
- [ ] 4.4 パターンマッチング処理を実装する
- [ ] 4.5 ファイルコピー処理を実装する
- [ ] 4.6 エラーハンドリングを追加する

---

## 5. scripts/sync.shの実装

- [ ] 5.1 `scripts/sync.sh` を作成する
- [ ] 5.2 git-xargsのインストール処理を実装する
- [ ] 5.3 git-xargsの実行コマンドを構築する
- [ ] 5.4 環境変数（`GITHUB_OAUTH_TOKEN`）の設定を実装する
- [ ] 5.5 ブランチ名の生成（タイムスタンプ付き）を実装する
- [ ] 5.6 PRタイトル・本文の設定を実装する

---

## 6. .github/workflows/distribute.ymlの実装

- [ ] 6.1 `.github/workflows/distribute.yml` を作成する
- [ ] 6.2 スケジュールトリガー（毎週月曜 2:00 JST）を設定する
  ```yaml
  schedule:
    - cron: '0 2 * * 1'
  ```
- [ ] 6.3 手動実行トリガー（`workflow_dispatch`）を設定する
- [ ] 6.4 GitHub App認証のステップを実装する
  - `tibdex/github-app-token` アクションを使用
- [ ] 6.5 チェックアウトステップを実装する
- [ ] 6.6 git-xargsのインストールステップを実装する
- [ ] 6.7 sync.shの実行ステップを実装する
- [ ] 6.8 必要な権限（permissions）を設定する

---

## 7. repos/ディレクトリの設定

- [ ] 7.1 `repos/test.txt` を作成する
  ```
  monokaai/demo-template-sync-a
  monokaai/demo-template-sync-b
  monokaai/demo-template-sync-c
  ```
- [ ] 7.2 `repos/production.txt` を作成する（本番用リポジトリを列挙）

---

## 8. 共通ファイルの配置

- [ ] 8.1 `.github/workflows/` ディレクトリを作成する
- [ ] 8.2 `.github/workflows/ci.yml` を作成する（サンプル）
- [ ] 8.3 `.eslintrc.json` を作成する（サンプル）
- [ ] 8.4 他の配布したいファイルを配置する

---

## 9. テスト実行（フェーズ1）

- [ ] 9.1 dry-runモードでテスト実行する
- [ ] 9.2 手動実行（`workflow_dispatch`）でテストする
- [ ] 9.3 PRが正しく作成されることを確認する
- [ ] 9.4 ファイルが正しくコピーされていることを確認する
- [ ] 9.5 パターンマッチングが動作していることを確認する
- [ ] 9.6 コンフリクト解決の流れを確認する
- [ ] 9.7 問題があれば修正する

---

## 10. GitHub App作成手順のドキュメント化

- [ ] 10.1 GitHub App作成手順をまとめる
  - GitHubの設定画面からの作成手順
  - 必要な権限の説明
  - Private Keyの取得手順
- [ ] 10.2 Organizationへのインストール手順をまとめる
- [ ] 10.3 Secrets設定手順をまとめる
