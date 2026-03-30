#!/bin/bash
# 安装 yaml-language-server 到 ~/.local/bin
# 可重入：已安装时跳过

set -e

BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/yaml-language-server"

if [[ -x "$BINARY" ]]; then
    echo "yaml-language-server 已安装"
    exit 0
fi

# 确保 Node.js 已安装
if ! command -v npm &>/dev/null; then
    echo "错误: npm 未安装，请先运行 install-node.sh"
    exit 1
fi

echo "安装 yaml-language-server"

mkdir -p "$BIN_DIR"
npm install -g yaml-language-server

echo ""
echo "yaml-language-server 安装完成: $BINARY"