#!/bin/bash
set -euo pipefail

# ==============================================================================
# sync.sh - git-xargs を使用して複数リポジトリに設定を配布する
# ==============================================================================

# デフォルト値
SOURCE_REPO="${SOURCE_REPO:-monokaai/demo-template-sync}"
BRANCH_NAME="${BRANCH_NAME:-update-config-$(date +%Y%m%d%H%M)}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-chore: sync common config from ${SOURCE_REPO}}"
PR_TITLE="${PR_TITLE:-🔄 Common Config Update}"
PR_BODY="${PR_BODY:-Automated sync from common-config repo. Please review and resolve any conflicts.}"
REPOS_FILE="${REPOS_FILE:-repos/test.txt}"

# git-xargs オプション
GIT_XARGS_FLAGS=(
  --loglevel debug
  --branch-name "$BRANCH_NAME"
  --commit-message "$COMMIT_MESSAGE"
  --pull-request-title "$PR_TITLE"
  --pull-request-description "$PR_BODY"
  --repos "$REPOS_FILE"
  --draft
  --seconds-between-prs 2
)

# dry-run チェック
if [[ "${DRY_RUN:-false}" == "true" ]]; then
  GIT_XARGS_FLAGS+=(--dry-run)
  echo "[sync.sh] DRY RUN MODE - No changes will be pushed"
fi

# ==============================================================================
# git-xargs のインストール
# ==============================================================================
install_git_xargs() {
  if command -v git-xargs &> /dev/null; then
    echo "[sync.sh] ✓ git-xargs already installed"
    git-xargs --version | head -1
  else
    echo "[sync.sh] Installing git-xargs..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # 最新リリースを取得
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/gruntwork-io/git-xargs/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "v([^"]+)".*/\1/')

    # OS に応じたバイナリ名を設定
    OS_TYPE=$(uname -s)
    case "$OS_TYPE" in
      Darwin)
        BINARY_NAME="git-xargs_darwin_amd64"
        ;;
      Linux)
        BINARY_NAME="git-xargs_linux_amd64"
        ;;
      *)
        echo "[sync.sh] ERROR: Unsupported OS: $OS_TYPE" >&2
        exit 1
        ;;
    esac

    DOWNLOAD_URL="https://github.com/gruntwork-io/git-xargs/releases/download/v${LATEST_RELEASE}/${BINARY_NAME}"

    echo "[sync.sh] Downloading git-xargs v${LATEST_RELEASE} for ${OS_TYPE}..."
    curl -LO "$DOWNLOAD_URL"
    chmod +x "$BINARY_NAME"
    sudo mv "$BINARY_NAME" /usr/local/bin/git-xargs

    cd -
    rm -rf "$TEMP_DIR"
    echo "[sync.sh] ✓ git-xargs installed successfully"
  fi
}

# ==============================================================================
# メイン処理
# ==============================================================================
main() {
  echo "[sync.sh] ============================================="
  echo "[sync.sh] Template Sync System"
  echo "[sync.sh] ============================================="
  echo "[sync.sh] Source Repository: ${SOURCE_REPO}"
  echo "[sync.sh] Branch Name: ${BRANCH_NAME}"
  echo "[sync.sh] Repos File: ${REPOS_FILE}"
  echo "[sync.sh] ============================================="

  # git-xargs のインストール
  install_git_xargs

  # Git トークンのチェック
  if [[ -z "${GITHUB_OAUTH_TOKEN:-}" ]]; then
    echo "[sync.sh] ERROR: GITHUB_OAUTH_TOKEN environment variable is not set" >&2
    echo "[sync.sh] Please export GITHUB_OAUTH_TOKEN before running this script" >&2
    exit 1
  fi

  # git-xargs の実行
  echo "[sync.sh] Running git-xargs..."
  # GitHub Raw URL からスクリプトをダウンロードして実行（キャッシュ回避のためタイムスタンプ追加）
  local timestamp=$(date +%s)
  local apply_script_url="https://raw.githubusercontent.com/${SOURCE_REPO}/main/scripts/apply.sh?t=${timestamp}"
  git-xargs "${GIT_XARGS_FLAGS[@]}" bash -c "curl -sL ${apply_script_url} | bash"

  echo "[sync.sh] ============================================="
  echo "[sync.sh] ✓ Complete!"
  echo "[sync.sh] ============================================="
}

main "$@"
