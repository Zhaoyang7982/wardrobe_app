#!/usr/bin/env bash
# 从本机「Apple Development」证书或描述文件中解析 Team ID，并生成 ios/Flutter/Signing.xcconfig（该文件已被 .gitignore）。
# 若解析失败：请先用 Xcode 打开 Runner.xcworkspace，在 Runner → Signing & Capabilities 里选一次 Personal Team，
# 等 Xcode 生成证书且不再报错后，关闭工程再执行本脚本。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR/Flutter/Signing.xcconfig"

team_from_keychain() {
  security find-identity -v -p codesigning 2>/dev/null \
    | perl -ne 'print "$1\n" if /Apple Development:.*\(([A-Z0-9]{10})\)/' \
    | head -n1
}

team_from_profiles() {
  local dir="$HOME/Library/MobileDevice/Provisioning Profiles"
  [[ -d "$dir" ]] || return 0
  local f tmp tid
  for f in "$dir"/*.mobileprovision; do
    [[ -f "$f" ]] || continue
    tmp="$(mktemp)"
    if security cms -D -i "$f" >"$tmp" 2>/dev/null; then
      tid="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$tmp" 2>/dev/null || true)"
      rm -f "$tmp"
      if [[ "$tid" =~ ^[A-Z0-9]{10}$ ]]; then
        echo "$tid"
        return 0
      fi
    else
      rm -f "$tmp"
    fi
  done
  return 1
}

TEAM="$(team_from_keychain || true)"
if [[ -z "${TEAM}" ]]; then
  TEAM="$(team_from_profiles || true)"
fi

if [[ -z "${TEAM}" ]]; then
  echo "未能自动检测到 Team ID。"
  echo ""
  echo "请在本机按顺序操作一次："
  echo "  1. 用 Xcode 打开 wardrobe_app/ios/Runner.xcworkspace"
  echo "  2. 左侧选 Runner 工程 → TARGETS → Runner → Signing & Capabilities"
  echo "  3. Team 下拉框选你的 Personal Team（个人团队），等待「Signing Certificate」就绪、无红色报错"
  echo "  4. 关闭 Xcode，回到终端再次执行："
  echo "       bash ios/configure_signing.sh"
  echo ""
  echo "若仍失败，可在 Xcode → Settings → Accounts → 选中 Apple ID → 团队详情里查看 10 位 Team ID，"
  echo "手动创建 $OUT ，内容为："
  echo "  DEVELOPMENT_TEAM = 你的十位TeamID"
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
cat >"$OUT" <<EOF
// 由 ios/configure_signing.sh 自动生成；勿提交仓库（见 ios/.gitignore）
DEVELOPMENT_TEAM = ${TEAM}
EOF

echo "已写入: $OUT"
echo "DEVELOPMENT_TEAM = ${TEAM}"
