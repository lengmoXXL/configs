#!/bin/bash

# 安装 ds-pinyin-lsp 拼音输入法 LSP
# 可重入：已安装时跳过

set -e

BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/ds-pinyin-lsp"
REPO_URL="https://github.com/lengmoXXL/ds-pinyin-lsp.git"

export RUSTUP_HOME="${HOME}/.local/rust/rustup"
export CARGO_HOME="${HOME}/.local/rust"

if [[ ! -x "$CARGO_HOME/bin/cargo" ]]; then
    echo "错误: Rust 未安装，请先运行 install-rust.sh"
    exit 1
fi

if [[ -x "$BINARY" ]]; then
    echo "ds-pinyin-lsp 已安装"
    exit 0
fi

echo "安装 ds-pinyin-lsp"

mkdir -p "$BIN_DIR"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "克隆仓库..."
git clone "$REPO_URL" "$TMPDIR/ds-pinyin-lsp"

echo "构建中..."
cd "$TMPDIR/ds-pinyin-lsp/packages/ds-pinyin-lsp"
"$CARGO_HOME/bin/cargo" build --release

cp target/release/ds-pinyin-lsp "$BINARY"

echo ""
echo "ds-pinyin-lsp 安装完成"
echo "  binary: $BINARY"
echo "  dict: 请使用 pinyin-dict-ctl.sh 初始化词典"
