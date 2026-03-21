#!/bin/bash
# 安装 typescript-language-server 到 ~/.local/typescript-language-server
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/typescript-language-server"
BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/typescript-language-server"

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "typescript-language-server 已安装"
    exit 0
fi

# 检查 npm 是否可用
if ! command -v npm &>/dev/null; then
    echo "错误: npm 未安装"
    exit 1
fi

echo "安装 typescript-language-server"

mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR"

# 使用 npm 安装到指定目录
npm install --prefix "$INSTALL_DIR" typescript typescript-language-server

# 创建符号链接
ln -sf "$INSTALL_DIR/node_modules/.bin/typescript-language-server" "$BINARY"
ln -sf "$INSTALL_DIR/node_modules/.bin/tsserver" "$BIN_DIR/tsserver"

echo ""
echo "typescript-language-server 安装完成: $BINARY"