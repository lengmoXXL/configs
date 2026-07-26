#!/bin/bash
# 安装 Kimi Code 主题到 ${KIMI_CODE_HOME:-~/.kimi-code}/themes/
# 可重入：重复执行会覆盖旧文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_SOURCE="$SCRIPT_DIR/kimi/themes"
KIMI_HOME="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
THEMES_DEST="$KIMI_HOME/themes"

usage() {
    cat << EOF
用法: $0

安装 Kimi Code 主题到 ${KIMI_CODE_HOME:-~/.kimi-code}/themes/。
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

if [[ ! -d "$THEMES_SOURCE" ]]; then
    echo "错误: 源目录不存在: $THEMES_SOURCE"
    exit 1
fi

mkdir -p "$THEMES_DEST"
cp "$THEMES_SOURCE"/*.json "$THEMES_DEST/"
echo "Kimi Code 主题已安装: $THEMES_DEST"
