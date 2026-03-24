#!/bin/bash
set -e

NPM="$HOME/.local/bin/npm"

if [[ ! -x "$NPM" ]]; then
    echo "错误: npm 未安装在 $NPM"
    echo "请先运行 install-node.sh 安装 Node.js"
    exit 1
fi

echo "==> Installing bash-language-server..."
"$NPM" install -g bash-language-server

echo "==> Done! bash-language-server installed to ~/.local/bin"