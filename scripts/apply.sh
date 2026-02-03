#!/bin/bash
set -euo pipefail

# 配布元リポジトリ
SOURCE_REPO="${SOURCE_REPO:-monokaai/demo-template-sync}"
SOURCE_DIR="/tmp/common-config-source-$$"

# Git clone 用 URL（認証付き）
if [[ -n "${GITHUB_OAUTH_TOKEN:-}" ]]; then
  SOURCE_URL="https://x-access-token:${GITHUB_OAUTH_TOKEN}@github.com/${SOURCE_REPO}.git"
else
  SOURCE_URL="https://github.com/${SOURCE_REPO}.git"
fi

# 配布元リポジトリをクローン
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[apply.sh] Cloning source repository: ${SOURCE_REPO}"
  git clone --depth 1 "$SOURCE_URL" "$SOURCE_DIR"
else
  echo "[apply.sh] Using cached source repository: ${SOURCE_DIR}"
fi

# ターゲットリポジトリ名（git-xargsから提供される環境変数）
REPO_NAME="${XARGS_REPO_NAME}"
echo "[apply.sh] Processing repository: ${REPO_NAME}"

# includes.txt のパス
INCLUDES_FILE="$SOURCE_DIR/includes.txt"

if [[ ! -f "$INCLUDES_FILE" ]]; then
  echo "[apply.sh] ERROR: includes.txt not found at $INCLUDES_FILE" >&2
  exit 1
fi

# includes.txt を解析してファイルをコピー
COPIED_COUNT=0
SKIPPED_COUNT=0

while IFS= read -r line; do
  # コメント行と空行をスキップ
  [[ "$line" =~ ^[[:space:]]*#.*$ ]] && continue
  [[ -z "$line" ]] && continue

  # パターンとファイルに分離
  if [[ "$line" == *:* ]]; then
    pattern="${line%%:*}"
    file="${line#*:}"

    # パターンマッチ（ワイルドカード展開）
    if [[ "$REPO_NAME" == ${pattern} ]]; then
      SOURCE_FILE="$SOURCE_DIR/$file"
      if [[ -f "$SOURCE_FILE" ]]; then
        mkdir -p "$(dirname "$file")"
        cp "$SOURCE_FILE" "$file"
        echo "[apply.sh] ✓ Copied: $file (pattern: $pattern)"
        ((COPIED_COUNT++))
      else
        echo "[apply.sh] ⚠ Skipped: $file (not found in source, pattern: $pattern)" >&2
        ((SKIPPED_COUNT++))
      fi
    fi
  else
    # パターンなし = 全リポジトリ
    SOURCE_FILE="$SOURCE_DIR/$line"
    if [[ -f "$SOURCE_FILE" ]]; then
      mkdir -p "$(dirname "$line")"
      cp "$SOURCE_FILE" "$line"
      echo "[apply.sh] ✓ Copied: $line (default)"
      ((COPIED_COUNT++))
    else
      echo "[apply.sh] ⚠ Skipped: $line (not found in source)" >&2
      ((SKIPPED_COUNT++))
    fi
  fi
done < "$INCLUDES_FILE"

echo "[apply.sh] Summary: $COPIED_COUNT files copied, $SKIPPED_COUNT files skipped"

# ファイル変更がない場合の処理
if [[ $COPIED_COUNT -eq 0 ]]; then
  echo "[apply.sh] No files were copied. Exiting."
  exit 0
fi

echo "[apply.sh] ✓ Complete"
