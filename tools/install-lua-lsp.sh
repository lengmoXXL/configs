#!/bin/bash

# 安装 lua-language-server 到 ~/.local/lua-language-server
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/lua-language-server"
BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/lua-language-server"
PROXY="${GITHUB_PROXY:-https://ghproxy.com/}"

if [[ -x "$BINARY" ]]; then
    echo "lua-language-server 已安装"
    exit 0
fi

API_URL="${PROXY}https://api.github.com/repos/LuaLS/lua-language-server/releases/latest"
VERSION=$(curl -s "$API_URL" | grep -oP '"tag_name": "\K[^"]+')

echo "安装 lua-language-server $VERSION"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="x64" ;;
    aarch64) ARCH="arm64" ;;
    *)       echo "不支持的架构: $ARCH"; exit 1 ;;
esac

mkdir -p "$BIN_DIR"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"

DOWNLOAD_URL="${PROXY}https://github.com/LuaLS/lua-language-server/releases/download/$VERSION/lua-language-server-$VERSION-linux-$ARCH.tar.gz"
curl -fLO "$DOWNLOAD_URL"

mkdir -p "$INSTALL_DIR"
tar -xzf "lua-language-server-$VERSION-linux-$ARCH.tar.gz" -C "$INSTALL_DIR"
ln -sf "$INSTALL_DIR/bin/lua-language-server" "$BINARY"

echo ""
echo "lua-language-server 安装完成: $BINARY"