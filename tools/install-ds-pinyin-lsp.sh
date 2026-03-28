#!/bin/bash
# 安装 ds-pinyin-lsp 拼音输入法 LSP
# 可重入：已安装时跳过

set -e

BIN_DIR="${HOME}/.local/bin"
DATA_DIR="${HOME}/.local/share/ds-pinyin-lsp"
BINARY="$BIN_DIR/ds-pinyin-lsp"

# 设置 Rust 环境
export RUSTUP_HOME="${HOME}/.local/rust/rustup"
export CARGO_HOME="${HOME}/.local/rust"

# 检查 Rust 是否已安装
if [[ ! -x "$CARGO_HOME/bin/cargo" ]]; then
    echo "错误: Rust 未安装，请先运行 install-rust.sh"
    exit 1
fi

# 检查是否已安装
if [[ -x "$BINARY" ]]; then
    echo "ds-pinyin-lsp 已安装"
    exit 0
fi

echo "安装 ds-pinyin-lsp"

mkdir -p "$BIN_DIR"
mkdir -p "$DATA_DIR"

# 使用 cargo 安装
"$CARGO_HOME/bin/cargo" install ds-pinyin-lsp

# 创建符号链接
ln -sf "$CARGO_HOME/bin/ds-pinyin-lsp" "$BINARY"

# 下载字典文件
echo "下载字典文件 dict.db3..."
curl -fL "https://github.com/iamcco/ds-pinyin-lsp/releases/download/v0.4.0/dict.db3.zip" -o /tmp/dict.db3.zip
unzip -o /tmp/dict.db3.zip -d "$DATA_DIR/"
rm /tmp/dict.db3.zip

echo ""
echo "ds-pinyin-lsp 安装完成"
echo "  binary: $BINARY"
echo "  dict: $DATA_DIR/dict.db3"