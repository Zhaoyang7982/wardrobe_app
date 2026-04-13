#!/usr/bin/env bash
# 在国内网络下安装 Flutter + CocoaPods（不依赖 Homebrew、不访问 raw.githubusercontent.com）。
#
# 镜像配置（默认「清华 Pub + CFUG 存储」——清华 TUNA 的 dart-pub 可用；SDK 大文件在 TUNA 上常见路径曾 404，故 zip 下载自动多源回退）：
#   FLUTTER_MIRROR_PROFILE=tuna   （默认）清华 Pub + CFUG 工件 + SDK zip 先试清华再回退
#   FLUTTER_MIRROR_PROFILE=cfug  全部走 CFUG（pub.flutter-io.cn / storage.flutter-io.cn）
# 参考：https://docs.flutter.cn/community/china/ 、https://mirrors.tuna.tsinghua.edu.cn/help/flutter/
#
# 用法（在仓库根目录）：
#   bash scripts/bootstrap_mac_flutter_cn.sh
#
# 若下载中断，直接再次运行同一命令（curl 会断点续传）。
#
# 可选：仍想装 Homebrew 时，可换镜像安装脚本（自行承担第三方脚本风险），例如：
#   /bin/bash -c "$(curl -fsSL https://gitee.com/ineo6/homebrew-install/raw/master/install.sh)"

set -euo pipefail

PROFILE="${FLUTTER_MIRROR_PROFILE:-tuna}"
if [[ "$PROFILE" == "cfug" ]]; then
  export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
  export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
else
  # 清华 dart-pub；工件存储用 CFUG（与 Flutter 工具链期望的 flutter_infra_release 布局一致）
  export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://mirrors.tuna.tsinghua.edu.cn/dart-pub}"
  export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
fi

ROOT="${FLUTTER_HOME_DIR:-$HOME/development}"
VERSION="${FLUTTER_VERSION:-3.41.6}"
MARKER="# wardrobe_app: flutter-cn-mirror"

mkdir -p "$ROOT"
cd "$ROOT"

ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  ZIP_NAME="flutter_macos_arm64_${VERSION}-stable.zip"
else
  ZIP_NAME="flutter_macos_${VERSION}-stable.zip"
fi

pick_flutter_sdk_zip_url() {
  local cfug="https://storage.flutter-io.cn/flutter_infra_release/releases/stable/macos/${ZIP_NAME}"
  local tuna_a="https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/macos/${ZIP_NAME}"
  local tuna_b="https://mirrors.tuna.tsinghua.edu.cn/flutter_infra_release/releases/stable/macos/${ZIP_NAME}"
  local tuna_c="https://mirrors.tuna.tsinghua.edu.cn/flutter_infra/releases/stable/macos/${ZIP_NAME}"
  local u http
  if [[ "$PROFILE" != "cfug" ]]; then
    for u in "$tuna_a" "$tuna_b" "$tuna_c"; do
      http="$(curl -sS -o /dev/null -w "%{http_code}" -L --connect-timeout 15 -I "$u" || true)"
      if [[ "$http" == "200" ]]; then
        echo "$u"
        return
      fi
    done
  fi
  echo "$cfug"
}

URL="$(pick_flutter_sdk_zip_url)"

if [[ -x "$ROOT/flutter/bin/flutter" ]]; then
  echo "已检测到 Flutter: $ROOT/flutter"
else
  echo "将从镜像下载: $URL"
  echo "（完整包约 2GB，请耐心等待；中断后可重新运行本脚本续传。）"
  rm -f "${ZIP_NAME}.corrupt"
  # 断点续传：第二次起对已存在的 ZIP 继续下载
  curl -fL --retry 15 --retry-delay 5 --connect-timeout 30 -C - -o "$ZIP_NAME" "$URL"
  if ! unzip -t "$ZIP_NAME" >/dev/null 2>&1; then
    echo "ZIP 校验失败，请删除后重试: rm -f \"$ROOT/$ZIP_NAME\""
    exit 1
  fi
  rm -rf "$ROOT/flutter"
  unzip -q "$ZIP_NAME"
  echo "解压完成。如需节省空间可手动删除: rm -f \"$ROOT/$ZIP_NAME\""
fi

GEMBIN="$(ruby -e 'puts Gem.user_dir')/bin"
mkdir -p "$GEMBIN"

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
touch "$ZSHRC"
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
  if [[ "$PROFILE" == "cfug" ]]; then
    cat >>"$ZSHRC" <<EOF

$MARKER
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PATH="$ROOT/flutter/bin:$GEMBIN:\$PATH"
EOF
  else
    cat >>"$ZSHRC" <<EOF

$MARKER
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PATH="$ROOT/flutter/bin:$GEMBIN:\$PATH"
EOF
  fi
  echo "已追加 Flutter 镜像、PATH（含 CocoaPods gem 目录）到: $ZSHRC"
fi

export PATH="$ROOT/flutter/bin:$GEMBIN:$PATH"
"$ROOT/flutter/bin/flutter" --version

if ! command -v pod >/dev/null 2>&1; then
  echo "正在安装 CocoaPods（用户目录，无需 sudo）..."
  # macOS 自带 Ruby 2.6 时，先固定一组兼容版本再装 CocoaPods 1.11.x
  RUBY_VER="$(ruby -e 'puts RUBY_VERSION[/^\d+\.\d+/]')"
  if [[ "$RUBY_VER" == "2.6" ]]; then
    gem install ffi -v 1.15.5 --user-install --no-document
    gem install securerandom -v 0.3.2 --user-install --no-document
    gem install zeitwerk -v 2.6.18 --user-install --no-document
    gem install cocoapods -v 1.11.3 --user-install --no-document
  else
    gem install cocoapods --user-install --no-document
  fi
fi

pod --version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
echo "运行 flutter pub get..."
flutter pub get
echo "运行 pod install..."
# 若曾配置 gitclone.com 代替 GitHub，CocoaPods 拉 Pod 时会 502，这里静默清理
git config --global --unset-all "url.https://gitclone.com/github.com/.insteadof" 2>/dev/null || true
git config --global --unset-all "url.https://gitclone.com/github.com/.insteadOf" 2>/dev/null || true
cd ios
pod install
cd ..

echo ""
echo "完成。请在新终端执行:  source ~/.zshrc"
echo "然后:  flutter doctor"
echo "Xcode 请继续用 ios/Runner.xcworkspace 打开工程。"
