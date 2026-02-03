# GitHub App 作成・設定手順

このドキュメントでは、Template Sync System で使用する GitHub App の作成と設定手順を説明します。

---

## 1. GitHub App の作成

### 1.1 GitHub App ページへ移動

1. GitHub にログイン
2. 以下のURLにアクセス: https://github.com/settings/apps
3. 「New GitHub App」ボタンをクリック

### 1.2 Basic Information

GitHub App 作成画面の「Basic information」セクションに入力する項目です：

| 項目 | 説明 | 設定値 |
| :--- | :--- | :--- |
| **GitHub App name** | GitHub App の識別名。Organization内で一意である必要があります。 | `template-sync-app` （任意の名前） |
| **Homepage URL** | このアプリに関連付けるWebページのURL。通常はリポジトリのURLを指定します。 | `https://github.com/monokaai/demo-template-sync` |
| **Description** | GitHub App の用途を説明する短文。Organizationの他のメンバーに何のためのアプリか分かるように書きます。 | `Template sync system for distributing common config files` |

### 1.3 権限の設定

**Repository permissions:**

| Permission | Access |
|------------|--------|
| Contents | Read and write |
| Pull requests | Read and write |
| Metadata | Read-only |

**Organization permissions:**
- 特に設定不要（リポジトリ権限のみで動作）

### 1.4 Webhook の設定

- **Webhook URL**: 空欄で進められない場合は、以下のダミーURLを入力してください
  - `https://example.com` （あとで無効になるURL）
  - または、空欄にして進みます（「Active」チェックを外した状態）
  - Webhook URL は外部システムからこのアプリに通知を送るためのURLですが、このシステムではGitHub Actionsから呼び出すため不要です
- **Active**: チェックを外す（このシステムでは使用しない）

### 1.5 作成

「Create GitHub App」ボタンをクリック

---

## 2. Private Key と App ID の取得

### 2.1 Private Key のダウンロード

1. 作成した GitHub App のページで「General」セクションを確認
2. 「Private keys」セクションで「Generate a private key」をクリック
3. 「Generate private key」ボタンをクリック
4. `.pem` ファイルがダウンロードされる
5. **重要**: このファイルは後で使用するため、安全な場所に保存してください

### 2.2 App ID の確認

1. 「General」セクションの「App ID」をメモする
2. このIDは後で Actions Secrets に登録します

---

## 3. Organization へのインストール

### 3.1 GitHub App のインストール

1. GitHub App ページの左側メニューから「Install App」をクリック
2. ターゲットの Organization を選択
3. **Repository access**: 「All repositories」を選択
4. 「Install」ボタンをクリック

---

## 4. Actions Secrets への登録

### 4.1 Secrets を登録するリポジトリ

この GitHub App を使用するリポジトリ（`demo-template-sync`）の Secrets に登録します。

### 4.2 Secrets の登録手順

1. `demo-template-sync` リポジトリの「Settings」タブを開く
2. 左側メニューから「Secrets and variables」→「Actions」をクリック
3. 「New repository secret」ボタンをクリック
4. 以下の2つの Secret を登録

#### Secret 1: APP_ID

| 項目 | 値 |
|------|---|
| **Name** | `APP_ID` |
| **Secret** | 手順 2.2 でメモした App ID |
| **Environment** | （空のまま） |

#### Secret 2: APP_PRIVATE_KEY

| 項目 | 値 |
|------|---|
| **Name** | `APP_PRIVATE_KEY` |
| **Secret** | 手順 2.1 でダウンロードした `.pem` ファイルの内容全体をコピー&ペースト |
| **Environment** | （空のまま） |

**注意**: `.pem` ファイルの内容をテキストエディタで開き、全体をコピーして Secret 値として貼り付けてください。

---

## 5. 動作確認

### 5.1 権限の確認

以下の手順で権限が正しく設定されているか確認できます：

1. GitHub App ページで「Install App」をクリック
2. Organization 名の下に「Installed」と表示されていることを確認
3. リポジトリ数が正しく表示されていることを確認

### 5.2 テスト実行

GitHub Actions が正常に動作するかテスト実行します：

```bash
# ローカルでテスト（GitHub App トークンが必要）
export GITHUB_OAUTH_TOKEN=<GitHub App トークン>
./scripts/sync.sh
```

---

## トラブルシューティング

### エラー: Resource not accessible by integration

**原因**: GitHub App がリポジトリにアクセスする権限がない

**解決策**:
1. GitHub App の「Install App」ページを確認
2. リポジトリが正しく選択されているか確認
3. 権限設定を確認（Contents: Write, Pull requests: Write）

### エラー: Bad credentials

**原因**: App ID または Private Key が正しくない

**解決策**:
1. Secret に登録した App ID が正しいか確認
2. Private Key が正しくコピーされているか確認（改行なし）
3. GitHub App が有効になっているか確認

---

## 参考リンク

- [GitHub Apps ドキュメント](https://docs.github.com/en/developers/apps)
- [Creating a GitHub App](https://docs.github.com/en/developers/apps/creating-a-github-app)
- [tibdex/github-app-token アクション](https://github.com/tibdex/github-app-token)
