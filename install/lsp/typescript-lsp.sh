#!/bin/bash
# 安装 typescript-language-server 到 ~/.local/typescript-language-server
# 可重入：已安装时跳过

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" && pwd)/common.sh"

INSTALL_DIR="${HOME}/.local/typescript-language-server"
BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/typescript-language-server"

if [[ "${UPDATE:-}" == "1" && ! -x "$BINARY" ]]; then
    echo "未安装，跳过: $BINARY"
    exit 0
fi

if [[ -x "$BINARY" && "${UPDATE:-}" != "1" ]]; then
    echo "typescript-language-server 已安装"
    exit 0
fi

if ! command -v npm &>/dev/null; then
    echo "错误: npm 未安装"
    exit 1
fi

if [[ "${UPDATE:-}" == "1" ]]; then
    confirm_update "typescript-language-server 到最新版" || exit 0
fi

echo "安装 typescript-language-server"

mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR"

npm install --prefix "$INSTALL_DIR" typescript@^6 typescript-language-server

ln -sf "$INSTALL_DIR/node_modules/.bin/typescript-language-server" "$BINARY"
ln -sf "$INSTALL_DIR/node_modules/.bin/tsserver" "$BIN_DIR/tsserver"

echo ""
echo "typescript-language-server 安装完成: $BINARY"