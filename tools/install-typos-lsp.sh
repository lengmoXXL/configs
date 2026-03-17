#!/bin/bash
# 安装 typos-lsp (拼写检查 LSP)
# 可重入：已安装时跳过

set -e

BIN_DIR="${HOME}/.local/bin"
VERSION="v0.1.50"

# 检测架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="x86_64-unknown-linux-gnu" ;;
    aarch64) ARCH="aarch64-unknown-linux-gnu" ;;
    *)       echo "不支持的架构: $ARCH"; exit 1 ;;
esac

BINARY="$BIN_DIR/typos-lsp"

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "typos-lsp 已安装"
    exit 0
fi

echo "安装 typos-lsp $VERSION ($ARCH)"

mkdir -p "$BIN_DIR"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"

curl -LO "https://gh-proxy.com/https://github.com/tekumara/typos-lsp/releases/download/$VERSION/typos-lsp-$VERSION-$ARCH.tar.gz"
tar -xzf "typos-lsp-$VERSION-$ARCH.tar.gz"
mv typos-lsp "$BINARY"

echo ""
echo "typos-lsp 安装完成: $BINARY"