#!/bin/bash
# 安装 typos-lsp (拼写检查 LSP) - 从源码编译
# 可重入：已安装时跳过
# 依赖: ~/.local/rust 中的 Rust 环境

set -e

RUST_DIR="${HOME}/.local/rust"
BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/typos-lsp"

export RUSTUP_HOME="$RUST_DIR/rustup"
export CARGO_HOME="$RUST_DIR"

# 检查 Rust 是否已安装
if [[ ! -x "$RUST_DIR/bin/cargo" ]]; then
    echo "错误: Rust 未安装，请先运行 install-rust.sh"
    exit 1
fi

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "typos-lsp 已安装"
    exit 0
fi

echo "从源码编译安装 typos-lsp"

mkdir -p "$BIN_DIR"

# 使用隔离的 Rust 环境从 git 编译
"$RUST_DIR/bin/cargo" install --git https://github.com/tekumara/typos-lsp --tag v0.1.49 --locked

# 创建符号链接
ln -sf "$RUST_DIR/bin/typos-lsp" "$BINARY"

echo ""
echo "typos-lsp 安装完成: $BINARY"