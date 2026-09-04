#!/bin/bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" && pwd)/common.sh"

BIN_DIR="$HOME/.local/bin"
NPM="$BIN_DIR/npm"
BINARY="$BIN_DIR/bash-language-server"

if [[ ! -x "$NPM" ]]; then
    echo "错误: npm 未安装在 $NPM"
    echo "请先运行 install/compiler/node.sh 安装 Node.js"
    exit 1
fi

if [[ "${UPDATE:-}" == "1" && ! -x "$BINARY" ]]; then
    echo "未安装，跳过: $BINARY"
    exit 0
fi

if [[ -x "$BINARY" && "${UPDATE:-}" != "1" ]]; then
    echo "bash-language-server 已安装"
    exit 0
fi

if [[ "${UPDATE:-}" == "1" ]]; then
    confirm_update "bash-language-server 到最新版" || exit 0
fi

echo "==> Installing bash-language-server..."
"$NPM" install -g bash-language-server

echo "==> Done! bash-language-server installed to $BIN_DIR"
