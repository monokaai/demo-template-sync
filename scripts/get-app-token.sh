#!/bin/bash
set -euo pipefail

# ==============================================================================
# get-app-token.sh - GitHub App のトークンを生成する
# ==============================================================================

# デフォルト値
APP_ID="${APP_ID:-}"
APP_PRIVATE_KEY_PATH="${APP_PRIVATE_KEY_PATH:-.github-app-private-key.pem}"
GITHUB_API_BASE_URL="${GITHUB_API_BASE_URL:-https://api.github.com}"

# ==============================================================================
# JWT 生成関数
# ==============================================================================
generate_jwt() {
  local app_id="$1"
  local private_key_path="$2"

  # 現在のUnixタイムスタンプ
  local now=$(date +%s)

  # JWT ペイロード (有効期限10分)
  local payload=$(cat <<EOF
{
  "iat": ${now},
  "exp": $((now + 600)),
  "iss": ${app_id}
}
EOF
)

  # Base64URL エンコード
  local header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '\n=' | tr '+/' '-_')
  local payload_encoded=$(echo -n "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')

  # 署名
  local signature=$(echo -n "${header}.${payload_encoded}" | openssl dgst -sha256 -sign "$private_key_path" | base64 | tr -d '\n=' | tr '+/' '-_')

  echo "${header}.${payload_encoded}.${signature}"
}

# ==============================================================================
# メイン処理
# ==============================================================================
main() {
  echo "[get-app-token] =============================================="
  echo "[get-app-token] GitHub App Token Generator"
  echo "[get-app-token] =============================================="

  # APP_ID のチェック
  if [[ -z "$APP_ID" ]]; then
    echo "[get-app-token] ERROR: APP_ID environment variable is not set" >&2
    echo "[get-app-token] Usage: APP_ID=123456 ./scripts/get-app-token.sh" >&2
    exit 1
  fi

  # Private Key ファイルのチェック
  if [[ ! -f "$APP_PRIVATE_KEY_PATH" ]]; then
    echo "[get-app-token] ERROR: Private key file not found at $APP_PRIVATE_KEY_PATH" >&2
    echo "[get-app-token] Please download the private key from GitHub App settings" >&2
    exit 1
  fi

  echo "[get-app-token] App ID: ${APP_ID}"
  echo "[get-app-token] Private Key: ${APP_PRIVATE_KEY_PATH}"
  echo "[get-app-token] =============================================="

  # JWT を生成
  echo "[get-app-token] Generating JWT..."
  local jwt=$(generate_jwt "$APP_ID" "$APP_PRIVATE_KEY_PATH")

  # インストールIDを取得
  echo "[get-app-token] Getting installation ID..."
  local installations=$(curl -s "${GITHUB_API_BASE_URL}/app/installations" \
    -H "Authorization: Bearer ${jwt}" \
    -H "Accept: application/vnd.github+json")

  local installation_id=$(echo "$installations" | jq -r '.[0].id // empty')

  if [[ -z "$installation_id" ]]; then
    echo "[get-app-token] ERROR: No installation found. Please install the GitHub App to your organization." >&2
    exit 1
  fi

  echo "[get-app-token] Installation ID: ${installation_id}"

  # アクセストークンを取得
  echo "[get-app-token] Getting access token..."
  local response=$(curl -s "${GITHUB_API_BASE_URL}/app/installations/${installation_id}/access_tokens" \
    -X POST \
    -H "Authorization: Bearer ${jwt}" \
    -H "Accept: application/vnd.github+json")

  local token=$(echo "$response" | jq -r '.token // empty')

  if [[ -z "$token" ]]; then
    echo "[get-app-token] ERROR: Failed to get access token" >&2
    echo "[get-app-token] Response: ${response}" >&2
    exit 1
  fi

  echo "[get-app-token] =============================================="
  echo "[get-app-token] ✓ Token generated successfully!"
  echo "[get-app-token] =============================================="
  echo ""
  echo "export GITHUB_OAUTH_TOKEN=${token}"
  echo ""
  echo "Copy the above line and paste it into your terminal."
  echo ""
  echo "Token expires in 1 hour."
  echo "[get-app-token] =============================================="
}

main "$@"
