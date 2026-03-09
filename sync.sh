#!/bin/bash
# 将机器上的 nvim 配置同步到代码库

set -e

SOURCE="$HOME/.config/nvim/init.lua"
DEST="$(dirname "$0")/nvim/init.lua"

if [ ! -f "$SOURCE" ]; then
    echo "错误: 源文件不存在: $SOURCE"
    exit 1
fi

cp "$SOURCE" "$DEST"
echo "已同步: $SOURCE -> $DEST"
