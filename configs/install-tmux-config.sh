#!/bin/bash
# 安装 tmux 配置到 ~/.tmux.conf
# 可重入：重复执行会覆盖旧配置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SOURCE="$SCRIPT_DIR/tmux/tmux.conf"
TMUX_DEST="$HOME/.tmux.conf"

if [[ ! -f "$TMUX_SOURCE" ]]; then
    echo "错误: 源配置不存在: $TMUX_SOURCE"
    exit 1
fi

cp "$TMUX_SOURCE" "$TMUX_DEST"
echo "tmux 配置已安装: $TMUX_DEST"
