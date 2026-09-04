#!/bin/bash
# 安装 tree-sitter 到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"

echo "安装目录: $BIN_DIR/tree-sitter"

if [[ "${UPDATE:-}" == "1" ]]; then
    if [[ -x "$BIN_DIR/tree-sitter" ]]; then
        echo "tree-sitter 已安装，跳过（未固定版本）"
    else
        echo "未安装，跳过: $BIN_DIR/tree-sitter"
    fi
    exit 0
fi

if [[ -x "$BIN_DIR/tree-sitter" ]]; then
    echo "tree-sitter 已安装: $($BIN_DIR/tree-sitter --version)"
    exit 0
fi

RUST_DIR="${HOME}/.local/rust"
if [[ -x "$RUST_DIR/bin/cargo" ]]; then
    export RUSTUP_HOME="$RUST_DIR/rustup"
    export CARGO_HOME="$RUST_DIR"
    CARGO="$RUST_DIR/bin/cargo"
elif command -v cargo &>/dev/null; then
    CARGO="$(command -v cargo)"
else
    echo "错误: 缺少 cargo，请先运行 install/compiler/rust.sh" >&2
    exit 1
fi

mkdir -p "$BIN_DIR"

echo "编译安装 tree-sitter-cli..."
"$CARGO" install tree-sitter-cli

ln -sf "$(dirname "$CARGO")/tree-sitter" "$BIN_DIR/tree-sitter"

echo ""
echo "安装完成: $BIN_DIR/tree-sitter"
$BIN_DIR/tree-sitter --version