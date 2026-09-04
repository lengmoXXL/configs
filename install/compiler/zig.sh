#!/bin/bash
# 安装 Zig 编译器到 ~/.local/zig
# https://ziglang.org/

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" && pwd)/common.sh"

ZIG_DIR="${HOME}/.local/zig"
BIN_DIR="${HOME}/.local/bin"

ZIG_VERSION="${1:-0.14.0}"

ZIG_BIN="$ZIG_DIR/zig"

echo "安装 Zig $ZIG_VERSION"

if [[ "${UPDATE:-}" == "1" && ! -x "$ZIG_BIN" ]]; then
    echo "未安装，跳过: $ZIG_BIN"
    exit 0
fi

if [[ -x "$ZIG_BIN" ]]; then
    current_version=$("$ZIG_BIN" version 2>/dev/null || echo "unknown")
    if [[ "$current_version" == "$ZIG_VERSION" ]]; then
        echo "Zig $ZIG_VERSION 已安装: $ZIG_BIN"
        "$ZIG_BIN" version
        exit 0
    fi
    echo "Zig 版本不匹配 (当前: $current_version, 需要: $ZIG_VERSION)，重新安装..."
    confirm_update "zig: $current_version -> $ZIG_VERSION" || exit 0
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ZIG_ARCH="x86_64" ;;
    aarch64) ZIG_ARCH="aarch64" ;;
    *)       echo "错误: 不支持的架构 $ARCH"; exit 1 ;;
esac

ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
ZIG_TMP="/tmp/zig-${ZIG_VERSION}.tar.xz"

echo "下载中..."
curl -fsSL "$ZIG_URL" -o "$ZIG_TMP"

if [[ -d "$ZIG_DIR" ]]; then
    rm -rf "$ZIG_DIR"
fi

mkdir -p "$ZIG_DIR"
tar -xf "$ZIG_TMP" -C "$ZIG_DIR" --strip-components=1
rm "$ZIG_TMP"

mkdir -p "$BIN_DIR"
ln -sf "$ZIG_BIN" "$BIN_DIR/zig"

echo ""
echo "✓ Zig $ZIG_VERSION 安装完成"
echo "  binary: $ZIG_BIN"
echo "  link:   $BIN_DIR/zig"
"$ZIG_BIN" version