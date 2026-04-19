#!/bin/bash
set -e

BIN_DIR="$HOME/.local/bin"
NPM="$BIN_DIR/npm"
BINARY="$BIN_DIR/bash-language-server"

if [[ ! -x "$NPM" ]]; then
    echo "错误: npm 未安装在 $NPM"
    echo "请先运行 ../install-node.sh 安装 Node.js"
    exit 1
fi

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "bash-language-server 已安装"
    exit 0
fi

echo "==> Installing bash-language-server..."
"$NPM" install -g bash-language-server

echo "==> Done! bash-language-server installed to $BIN_DIR"
