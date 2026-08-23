#!/bin/bash
# 安装 dprint 全局配置到 ~/.config/dprint/dprint.jsonc
# 可重入：重复执行会覆盖旧配置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DPRINT_SOURCE="$SCRIPT_DIR/dprint/dprint.jsonc"
DPRINT_DIR="$HOME/.config/dprint"
DPRINT_DEST="$DPRINT_DIR/dprint.jsonc"

usage() {
    cat << EOF
用法: $0

安装 dprint 全局配置到 ~/.config/dprint/dprint.jsonc。
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

if [[ ! -f "$DPRINT_SOURCE" ]]; then
    echo "错误: 源配置不存在: $DPRINT_SOURCE"
    exit 1
fi

mkdir -p "$DPRINT_DIR"
cp "$DPRINT_SOURCE" "$DPRINT_DEST"
echo "dprint 全局配置已安装: $DPRINT_DEST"

if ! command -v dprint &>/dev/null; then
    echo "提示: dprint 未安装，可先运行 ./install/install-dprint.sh"
fi
