#!/bin/bash
# 将代码库的 nvim 配置更新到机器上

set -e

SOURCE="$(dirname "$0")/nvim/init.lua"
DEST="$HOME/.config/nvim/init.lua"

if [ ! -f "$SOURCE" ]; then
    echo "错误: 源文件不存在: $SOURCE"
    exit 1
fi

mkdir -p "$HOME/.config/nvim"
cp "$SOURCE" "$DEST"
echo "已安装: $SOURCE -> $DEST"
