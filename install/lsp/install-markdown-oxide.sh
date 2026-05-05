#!/bin/bash
# 安装 markdown-oxide LSP Server
# 从 fork 源码编译安装: https://github.com/lengmoXXL/markdown-oxide

set -e

REPO_URL="https://github.com/lengmoXXL/markdown-oxide.git"
BRANCH="${MARKDOWN_OXIDE_BRANCH:-main}"
RUST_DIR="${HOME}/.local/rust"
INSTALL_ROOT="${HOME}/.local/markdown-oxide"
BIN_DIR="${HOME}/.local/bin"
CARGO="${RUST_DIR}/bin/cargo"
BINARY="${BIN_DIR}/markdown-oxide"

export RUSTUP_DIST_SERVER="https://mirrors.aliyun.com/rustup"
export RUSTUP_UPDATE_ROOT="https://mirrors.aliyun.com/rustup/rustup"

if [[ -x "$CARGO" ]]; then
    export RUSTUP_HOME="${RUST_DIR}/rustup"
    export CARGO_HOME="${RUST_DIR}"
elif command -v cargo &>/dev/null; then
    CARGO="$(command -v cargo)"
else
    echo "错误: cargo 未安装"
    echo "请先运行 install/install-rust.sh 安装 Rust"
    exit 1
fi

echo "从源码安装 markdown-oxide"
echo "  repo: $REPO_URL"
echo "  branch: $BRANCH"

mkdir -p "$BIN_DIR" "$INSTALL_ROOT"

"$CARGO" install \
    --git "$REPO_URL" \
    --branch "$BRANCH" \
    --locked \
    --force \
    --root "$INSTALL_ROOT"

ln -sf "${INSTALL_ROOT}/bin/markdown-oxide" "$BINARY"

echo ""
echo "markdown-oxide LSP 安装完成:"
echo "  markdown-oxide: $BINARY"
echo "  version: $("$BINARY" --version)"
