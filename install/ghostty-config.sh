#!/bin/bash
# 安装 Ghostty 配置到 ~/.config/ghostty/config
# 可重入：重复执行会覆盖旧配置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_SOURCE="$SCRIPT_DIR/../configs/ghostty/config"
GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_DEST="$GHOSTTY_DIR/config"

usage() {
    cat << EOF
用法: $0

安装 Ghostty 配置到 ~/.config/ghostty/config。
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ ! -f "$GHOSTTY_SOURCE" ]]; then
    echo "错误: 源配置不存在: $GHOSTTY_SOURCE"
    exit 1
fi

mkdir -p "$GHOSTTY_DIR"
cp "$GHOSTTY_SOURCE" "$GHOSTTY_DEST"
echo "Ghostty 配置已安装: $GHOSTTY_DEST"

if ! command -v ghostty &>/dev/null; then
    echo "提示: ghostty 未安装"
    exit 0
fi

if ghostty +validate-config --config-file="$GHOSTTY_DEST" &>/dev/null; then
    echo "配置校验通过"
else
    echo "警告: 配置校验未通过，请运行 ghostty +validate-config 查看详情"
fi
