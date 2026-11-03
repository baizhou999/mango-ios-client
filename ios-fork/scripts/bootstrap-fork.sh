#!/usr/bin/env bash
set -euo pipefail

# 在 macOS 上运行：拉取 Telegram-iOS 并建立 Mango 分支。
# 用法：
#   ./bootstrap-fork.sh
#   PIN_COMMIT=<commit-sha> ./bootstrap-fork.sh

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/TelegramMessenger/Telegram-iOS.git}"
TARGET_DIR="${TARGET_DIR:-telegram-ios}"
PIN_COMMIT="${PIN_COMMIT:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -e "$TARGET_DIR" ]]; then
  echo "目标目录已存在：$TARGET_DIR" >&2
  exit 1
fi

git clone --recursive -j8 "$UPSTREAM_URL" "$TARGET_DIR"
cd "$TARGET_DIR"

if [[ -n "$PIN_COMMIT" ]]; then
  git checkout "$PIN_COMMIT"
  git submodule update --init --recursive -j8
fi

git switch -c mango/ios

mkdir -p mango
cp -R "$SCRIPT_DIR/../MangoFeatures" mango/MangoFeatures

echo "Telegram-iOS 已就绪：$(pwd)"
echo "MangoFeatures 已复制到 mango/MangoFeatures"
echo ""
echo "下一步："
echo "0. cd mango/MangoFeatures && swift test   # 先在 macOS 上验证移植逻辑"
echo "1. 编辑 build-system/template_minimal_development_configuration.json"
echo "   （填入自有 api_id/api_hash、Team ID、Bundle ID）"
echo "2. python3 build-system/Make/Make.py \\"
echo "     --cacheDir=\"\$HOME/telegram-bazel-cache\" \\"
echo "     generateProject \\"
echo "     --configurationPath=build-system/template_minimal_development_configuration.json \\"
echo "     --xcodeManagedCodesigning"
