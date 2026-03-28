#!/bin/bash
# 安装 wezterm 配置到 ~/.config/wezterm
# 可重入：已安装时跳过

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEZTERM_SOURCE="$SCRIPT_DIR/../configs/wezterm"
WEZTERM_DEST="$HOME/.config/wezterm"

if [[ ! -d "$WEZTERM_SOURCE" ]]; then
    echo "错误: 源目录不存在: $WEZTERM_SOURCE"
    exit 1
fi

mkdir -p "$WEZTERM_DEST"
cp -r "$WEZTERM_SOURCE"/* "$WEZTERM_DEST/"
echo "wezterm 配置已安装: $WEZTERM_DEST"