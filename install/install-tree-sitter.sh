#!/bin/bash
# 安装 tree-sitter 到 ~/.local/bin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

echo "安装目录: $BIN_DIR/tree-sitter"

# 检查是否已安装
if [[ -x "$BIN_DIR/tree-sitter" ]]; then
    echo "tree-sitter 已安装: $($BIN_DIR/tree-sitter --version)"
    exit 0
fi

# 调用 rust 安装脚本
bash "$SCRIPT_DIR/install-rust.sh"

# 设置 Rust 环境
export RUSTUP_HOME="${HOME}/.local/rust/rustup"
export CARGO_HOME="${HOME}/.local/rust"

mkdir -p "$BIN_DIR"

echo "编译安装 tree-sitter-cli..."
"$CARGO_HOME/bin/cargo" install tree-sitter-cli

# 创建符号链接
ln -sf "$CARGO_HOME/bin/tree-sitter" "$BIN_DIR/tree-sitter"

echo ""
echo "安装完成: $BIN_DIR/tree-sitter"
$BIN_DIR/tree-sitter --version