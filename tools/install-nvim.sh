#!/bin/bash
# 安装 nvim 配置到 ~/.config/nvim
# 可重入：已安装时跳过

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SOURCE="$SCRIPT_DIR/../configs/nvim"
NVIM_DEST="$HOME/.config/nvim"

if [[ ! -d "$NVIM_SOURCE" ]]; then
    echo "错误: 源目录不存在: $NVIM_SOURCE"
    exit 1
fi

rm -rf "$NVIM_DEST"
mkdir -p "$NVIM_DEST"
cp -r "$NVIM_SOURCE"/* "$NVIM_DEST/"
echo "nvim 配置已安装: $NVIM_DEST"