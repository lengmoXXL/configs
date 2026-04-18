#!/bin/bash
# 安装 typos-lsp (拼写检查 LSP)
# 支持两种模式：
#   --binary  从 GitHub 下载预编译包 (默认)
#   --source  从源码编译 (需要 Rust 环境)
# 可重入：已安装时跳过

set -e

MODE="binary"
VERSION="0.1.52"

while [[ $# -gt 0 ]]; do
    case $1 in
        --binary) MODE="binary"; shift ;;
        --source) MODE="source"; shift ;;
        *) echo "用法: $0 [--binary|--source]"; exit 1 ;;
    esac
done

BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/typos-lsp"

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "typos-lsp 已安装"
    exit 0
fi

mkdir -p "$BIN_DIR"

if [[ "$MODE" == "binary" ]]; then
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x86_64-unknown-linux-musl" ;;
        aarch64) ARCH="aarch64-unknown-linux-musl" ;;
        *) echo "错误: 不支持的架构 $ARCH"; exit 1 ;;
    esac

    URL="https://github.com/tekumara/typos-lsp/releases/download/v${VERSION}/typos-lsp-v${VERSION}-${ARCH}.tar.gz"
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    echo "下载 typos-lsp v${VERSION} (${ARCH})"
    curl -fsSL "$URL" | tar -xzf - -C "$TMPDIR"

    # 查找并安装二进制文件
    find "$TMPDIR" -name typos-lsp -type f -exec mv {} "$BINARY" \;
    chmod +x "$BINARY"
else
    # 从源码编译
    RUST_DIR="${HOME}/.local/rust"
    export RUSTUP_HOME="$RUST_DIR/rustup"
    export CARGO_HOME="$RUST_DIR"

    if [[ ! -x "$RUST_DIR/bin/cargo" ]]; then
        echo "错误: Rust 未安装，请先运行 install-rust.sh 或使用 --binary 模式"
        exit 1
    fi

    echo "从源码编译 typos-lsp"
    "$RUST_DIR/bin/cargo" install --git https://github.com/tekumara/typos-lsp --tag "v${VERSION}" --locked
    ln -sf "$RUST_DIR/bin/typos-lsp" "$BINARY"
fi

echo ""
echo "typos-lsp 安装完成: $BINARY"