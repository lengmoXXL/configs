#!/bin/bash
# 安装 pyright LSP 到 ~/.local/pyright
# 可重入：已安装时跳过

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_DIR="${HOME}/.local/pyright"
BIN_DIR="${HOME}/.local/bin"
NPM="${BIN_DIR}/npm"
PYRIGHT="${BIN_DIR}/pyright"
PYRIGHT_LANGSERVER="${BIN_DIR}/pyright-langserver"

if [[ -x "$PYRIGHT_LANGSERVER" ]]; then
    echo "pyright-langserver 已安装"
    exit 0
fi

if [[ ! -x "$NPM" ]]; then
    if command -v npm &>/dev/null; then
        NPM="$(command -v npm)"
    else
        echo "错误: npm 未安装"
        echo "请先运行 install/install-node.sh 安装 Node.js"
        exit 1
    fi
fi

echo "安装 pyright LSP"

mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR"

"$NPM" install --prefix "$INSTALL_DIR" pyright

ln -sf "$INSTALL_DIR/node_modules/.bin/pyright" "$PYRIGHT"
ln -sf "$INSTALL_DIR/node_modules/.bin/pyright-langserver" "$PYRIGHT_LANGSERVER"

echo ""
echo "pyright LSP 安装完成:"
echo "  pyright: $PYRIGHT"
echo "  pyright-langserver: $PYRIGHT_LANGSERVER"
