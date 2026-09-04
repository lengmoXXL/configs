#!/bin/bash
# 安装 Herdr 配置到 ~/.config/herdr/config.toml
# 可重入：内容变化才写入

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERDR_SOURCE="$SCRIPT_DIR/../configs/herdr/config.toml"
HERDR_DIR="$HOME/.config/herdr"
HERDR_DEST="$HERDR_DIR/config.toml"

usage() {
    cat << EOF
用法: $0

安装 Herdr 配置到 ~/.config/herdr/config.toml。
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

if [[ ! -f "$HERDR_SOURCE" ]]; then
    echo "错误: 源配置不存在: $HERDR_SOURCE"
    exit 1
fi

if [[ "${UPDATE:-}" == "1" && ! -e "$HERDR_DEST" ]]; then
    echo "未安装，跳过: $HERDR_DEST"
    exit 0
fi

tmp_config="$(mktemp)"
cp "$HERDR_SOURCE" "$tmp_config"
write_file_if_changed "$HERDR_DEST" "$tmp_config"

if ! command -v herdr &>/dev/null; then
    echo "提示: herdr 未安装，可先运行 ./install/herdr.sh"
    exit 0
fi

if herdr status server &>/dev/null; then
    herdr server reload-config >/dev/null
    echo "运行中的 Herdr server 已重新加载配置"
else
    echo "未检测到运行中的 Herdr server，配置将在下次启动时生效"
fi
