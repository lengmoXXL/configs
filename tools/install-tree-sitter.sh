#!/bin/bash
# 安装 tree-sitter 到 ~/.local/bin，最小化对系统环境的影响

set -e

INSTALL_DIR="${HOME}/.local/tree-sitter-build"
BIN_DIR="${HOME}/.local/bin"

echo "安装目录: $BIN_DIR/tree-sitter"

# 检查是否已安装
if [[ -x "$BIN_DIR/tree-sitter" ]]; then
    echo "tree-sitter 已安装: $($BIN_DIR/tree-sitter --version)"
    exit 0
fi

# 创建临时构建目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# 设置隔离的 Rust 环境
export RUSTUP_HOME="$INSTALL_DIR/rustup"
export CARGO_HOME="$INSTALL_DIR"

echo "安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain stable

echo "编译安装 tree-sitter-cli..."
"$INSTALL_DIR/bin/cargo" install tree-sitter-cli

# 复制到目标目录
cp "$INSTALL_DIR/bin/tree-sitter" "$BIN_DIR/tree-sitter"

# 清理构建环境
rm -rf "$INSTALL_DIR"

echo ""
echo "安装完成: $BIN_DIR/tree-sitter"
$BIN_DIR/tree-sitter --version